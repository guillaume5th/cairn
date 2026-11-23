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

/// Anthropic API stand-in by host: ok.test answers, the others fail the way the API does.
final class AnthropicStub: URLProtocol {
    static let requests = Mutex<[(request: URLRequest, body: Data)]>([])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        if let stream = request.httpBodyStream {
            stream.open()
            var body = Data(), buffer = [UInt8](repeating: 0, count: 4_096)
            while stream.hasBytesAvailable, case let n = stream.read(&buffer, maxLength: buffer.count), n > 0 {
                body.append(buffer, count: n)
            }
            stream.close()
            Self.requests.withLock { $0.append((request, body)) }
        }
        let (status, json): (Int, String) = switch url.host() {
        case "ok.test", "haiku.test":
            (200, #"{"content":[{"type":"thinking","thinking":""},{"type":"text","text":"Résumé "},{"type":"text","text":"de Claude"}],"stop_reason":"end_turn"}"#)
        case "refusal.test": (200, #"{"content":[],"stop_reason":"refusal"}"#)
        case "empty.test": (200, #"{"content":[{"type":"thinking","thinking":""}],"stop_reason":"end_turn"}"#)
        case "denied.test": (401, #"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#)
        case "billing.test": (402, #"{"type":"error","error":{"type":"billing_error","message":"credit"}}"#)
        case "unknown.test": (404, #"{"type":"error","error":{"type":"not_found_error","message":"model"}}"#)
        case "limited.test": (429, #"{"type":"error","error":{"type":"rate_limit_error","message":"slow down"}}"#)
        case "overloaded.test": (529, #"{"type":"error","error":{"type":"overloaded_error","message":"busy"}}"#)
        default: (500, "{}")
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

struct AnthropicSummarizerTests {
    let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AnthropicStub.self]
        return URLSession(configuration: config)
    }()

    func claude(_ host: String, key: String = "sk-test", model: String = "claude-opus-5-5") -> AnthropicSummarizer {
        AnthropicSummarizer(apiKey: key, model: model, baseURL: URL(string: "http://\(host)")!, session: session)
    }

    @Test func answerKeepsOnlyTextBlocks() async throws {
        #expect(try await claude("ok.test").summarize("Résume ça") == "Résumé de Claude")
        let (request, body) = try #require(AnthropicStub.requests.withLock { $0.last { $0.request.url?.host() == "ok.test" } })
        #expect(request.url?.path() == "/v1/messages")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2026-10-21")
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == "server-side-fallback-2026-07-01")
        #expect(try JSONDecoder().decode(AnthropicSummarizer.Request.self, from: body)
            == .init(model: "claude-opus-5-5", maxTokens: 16_000, fallbacks: "default",
                     messages: [.init(role: "user", content: "Résume ça")]))
    }

    @Test func haikuGetsNoFallback() async throws {
        // Its own host: tests run in parallel and would race for the last request of ok.test.
        _ = try await claude("haiku.test", model: "claude-haiku-5-5").summarize("x")
        let (request, body) = try #require(AnthropicStub.requests.withLock { $0.last { $0.request.url?.host() == "haiku.test" } })
        #expect(request.value(forHTTPHeaderField: "anthropic-beta") == nil)
        #expect(try JSONDecoder().decode(AnthropicSummarizer.Request.self, from: body).fallbacks == nil)
    }

    @Test func missingKeyNeverSendsARequest() async {
        await #expect(throws: CairnError.anthropicKeyMissing) { try await claude("ok.test", key: "").summarize("x") }
    }

    @Test func apiErrors() async {
        await #expect(throws: CairnError.anthropicKeyInvalid) { try await claude("denied.test").summarize("x") }
        await #expect(throws: CairnError.anthropicBilling) { try await claude("billing.test").summarize("x") }
        await #expect(throws: CairnError.anthropicModelNotFound("claude-opus-5-5")) { try await claude("unknown.test").summarize("x") }
        await #expect(throws: CairnError.anthropicRateLimited) { try await claude("limited.test").summarize("x") }
        await #expect(throws: CairnError.anthropicRateLimited) { try await claude("overloaded.test").summarize("x") }
        await #expect(throws: CairnError.httpStatus(500)) { try await claude("boom.test").summarize("x") }
    }

    @Test func refusalAndEmptyAnswerAreErrors() async {
        await #expect(throws: CairnError.anthropicRefused) { try await claude("refusal.test").summarize("x") }
        await #expect(throws: CairnError.summarizerUnavailable(Localization.string("Claude returned no text."))) {
            try await claude("empty.test").summarize("x")
        }
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
        let messages = reasons.map { AppleSummarizer.message(for: $0, language: "en") }
        #expect(Set(messages).count == 3)
        #expect(messages[1].contains("Apple Intelligence is turned off"))
    }
}

struct ClaudeCodeSummarizerTests {
    /// A folder with a fake `claude` script; `OUT` (given through the environment) is where it records what it got.
    private func fake(_ script: String, executable: Bool = true) throws -> (cli: URL, out: URL, env: [String: String]) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "cairn claude \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let cli = folder.appending(path: "claude")
        try Data("#!/bin/sh\n\(script)".utf8).write(to: cli)
        if executable { try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cli.path(percentEncoded: false)) }
        let out = folder.appending(path: "out")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        return (cli, out, ["OUT": out.path(percentEncoded: false), "ANTHROPIC_API_KEY": "sk-secret", "PATH": "/usr/bin:/bin"])
    }

    private func recorded(_ name: String, in out: URL) throws -> String {
        try String(contentsOf: out.appending(path: name), encoding: .utf8)
    }

    private static let recording = """
    printf '%s\\n' "$@" > "$OUT/args"
    cat > "$OUT/stdin"
    pwd > "$OUT/cwd"
    echo "${ANTHROPIC_API_KEY-unset}" > "$OUT/key"
    """

    @Test func answerAndHowTheCLIIsCalled() async throws {
        let (cli, out, env) = try fake(Self.recording + "\necho '{\"is_error\":false,\"result\":\"  Résumé Claude  \"}'\n")

        let text = try await ClaudeCodeSummarizer(executable: cli, model: "claude-haiku-5-5", environment: env).summarize("Résume ça ✓")

        #expect(text == "Résumé Claude")
        #expect(try recorded("stdin", in: out) == "Résume ça ✓")
        // No tool, no MCP, no user settings (hooks), no skills: an article cannot make Claude act on the Mac.
        let args = try recorded("args", in: out).split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(args.starts(with: ["-p", "--output-format", "json", "--tools", "", "--strict-mcp-config", "--disable-slash-commands",
                                   "--no-session-persistence", "--setting-sources", "", "--model", "claude-haiku-5-5"]))
        // The logged-in account is used, not an exported key; and the CLI starts in an empty folder of its own.
        #expect(try recorded("key", in: out).trimmingCharacters(in: .whitespacesAndNewlines) == "unset")
        let cwd = try recorded("cwd", in: out).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(cwd.contains("cairn-claude-"))
        #expect(!FileManager.default.fileExists(atPath: cwd), "the working folder is removed afterwards")
    }

    @Test func noModelMeansTheCLIDefault() async throws {
        let (cli, out, env) = try fake(Self.recording + "\necho '{\"is_error\":false,\"result\":\"ok\"}'\n")
        _ = try await ClaudeCodeSummarizer(executable: cli, environment: env).summarize("x")
        #expect(try !recorded("args", in: out).contains("--model"))
    }

    @Test func notLoggedIn() async throws {
        // As the real CLI does: exit status 1, but the JSON is still written.
        let (cli, _, env) = try fake("echo '{\"is_error\":true,\"result\":\"Not logged in · Please run /login\"}'\nexit 1\n")
        await #expect(throws: CairnError.claudeCodeNotLoggedIn) { try await ClaudeCodeSummarizer(executable: cli, environment: env).summarize("x") }
    }

    @Test func otherCLIError() async throws {
        let (cli, _, env) = try fake("echo '{\"is_error\":true,\"result\":\"Usage limit reached\"}'\nexit 1\n")
        await #expect(throws: CairnError.claudeCodeFailed("Usage limit reached")) {
            try await ClaudeCodeSummarizer(executable: cli, environment: env).summarize("x")
        }
    }

    @Test func unreadableOutput() async throws {
        let (cli, _, env) = try fake("echo 'not json'\nexit 3\n")
        await #expect(throws: CairnError.claudeCodeFailed(Localization.string("unreadable response (code \(Int32(3)))"))) {
            try await ClaudeCodeSummarizer(executable: cli, environment: env).summarize("x")
        }
    }

    @Test func missingOrNonExecutableCLI() async throws {
        let (plain, _, env) = try fake("exit 0\n", executable: false)
        await #expect(throws: CairnError.claudeCodeNotFound) { try await ClaudeCodeSummarizer(executable: plain, environment: env).summarize("x") }
        await #expect(throws: CairnError.claudeCodeNotFound) {
            try await ClaudeCodeSummarizer(executable: URL(filePath: "/nonexistent/claude"), environment: env).summarize("x")
        }
    }

    @Test func slowCLIIsStopped() async throws {
        let (cli, _, env) = try fake("sleep 30\n")
        await #expect(throws: CairnError.claudeCodeFailed(Localization.string("timed out (\(1) s)"))) {
            try await ClaudeCodeSummarizer(executable: cli, environment: env, timeout: 1).summarize("x")
        }
    }

    @Test func locateTakesTheFirstExecutable() throws {
        let (first, _, _) = try fake("exit 0\n", executable: false)
        let (second, _, _) = try fake("exit 0\n")
        let (third, _, _) = try fake("exit 0\n")
        #expect(ClaudeCodeSummarizer.locate(in: [first, second, third]) == second)
        #expect(ClaudeCodeSummarizer.locate(in: [first, URL(filePath: "/nonexistent/claude")]) == nil)
        #expect(ClaudeCodeSummarizer.defaultCandidates(home: URL(filePath: "/Users/x")).first?.path() == "/Users/x/.local/bin/claude")
    }
}
