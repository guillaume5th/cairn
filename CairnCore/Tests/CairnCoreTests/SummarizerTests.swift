@testable import CairnCore
import Foundation
import FoundationModels
import Synchronization
import Testing

/// Ollama stand-in by host: ollama.test answers, missing.test is 404, down.test refuses the connection.
final class OllamaStub: URLProtocol {
    static let bodies = Mutex<[Data]>([])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        if url.host() == "down.test" {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        // Only ollama.test bodies: tests run in parallel and the others would race for `bodies.last`.
        if url.host() == "ollama.test", let stream = request.httpBodyStream {
            stream.open()
            var body = Data(), buffer = [UInt8](repeating: 0, count: 4_096)
            while stream.hasBytesAvailable, case let n = stream.read(&buffer, maxLength: buffer.count), n > 0 {
                body.append(buffer, count: n)
            }
            stream.close()
            Self.bodies.withLock { $0.append(body) }
        }
        let found = url.host() == "ollama.test" && ["/api/generate", "/api/tags"].contains(url.path())
        let body = !found ? Data(#"{"error":"not found"}"#.utf8)
            : url.path() == "/api/tags" ? Data(#"{"models":[{"name":"llama3.2:latest","size":1},{"name":"gemma4:latest","size":2}]}"#.utf8)
            : Data(#"{"model":"m","response":"Résumé du jour","done":true}"#.utf8)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: found ? 200 : 404, httpVersion: nil, headerFields: nil)!,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

struct SummarizerTests {
    let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [OllamaStub.self]
        return URLSession(configuration: config)
    }()

    func ollama(_ host: String) -> OllamaSummarizer {
        OllamaSummarizer(baseURL: URL(string: "http://\(host):11434")!, model: "llama3.2", session: session)
    }

    @Test func ollamaAnswer() async throws {
        #expect(try await ollama("ollama.test").summarize("Résume ça") == "Résumé du jour")
        let sent = try #require(OllamaStub.bodies.withLock { $0.last })
        #expect(try JSONDecoder().decode(OllamaSummarizer.Request.self, from: sent)
            == .init(model: "llama3.2", prompt: "Résume ça", stream: false))
    }

    @Test func ollamaInstalledModels() async throws {
        #expect(try await ollama("ollama.test").installedModels() == ["gemma4:latest", "llama3.2:latest"])
        await #expect(throws: CairnError.ollamaUnreachable) { try await ollama("down.test").installedModels() }
    }

    @Test func ollamaModelNotFound() async throws {
        await #expect(throws: CairnError.ollamaModelNotFound("llama3.2")) { try await ollama("missing.test").summarize("x") }
    }

    @Test func ollamaUnreachable() async throws {
        await #expect(throws: CairnError.ollamaUnreachable) { try await ollama("down.test").summarize("x") }
    }

    @Test func appleUnavailabilityMessages() {
        let reasons: [SystemLanguageModel.Availability.UnavailableReason] = [.deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady]
        let messages = reasons.map(AppleSummarizer.message(for:))
        #expect(Set(messages).count == 3)
        #expect(messages[1].contains("Apple Intelligence est désactivé"))
    }
}
