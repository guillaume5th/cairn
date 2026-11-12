import Foundation
import FoundationModels

/// An AI engine running on this machine that turns a prompt into a summary.
public protocol Summarizer: Sendable {
    func summarize(_ prompt: String) async throws -> String
}

/// Apple's on-device model (Apple Intelligence).
public struct AppleSummarizer: Summarizer {
    public init() {}

    public func summarize(_ prompt: String) async throws -> String {
        if case let .unavailable(reason) = SystemLanguageModel.default.availability {
            throw CairnError.summarizerUnavailable(Self.message(for: reason))
        }
        return try await LanguageModelSession().respond(to: prompt).content
    }

    static func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible: "Cet appareil ne prend pas en charge Apple Intelligence. Choisis Ollama dans les Réglages."
        case .appleIntelligenceNotEnabled: "Apple Intelligence est désactivé. Active-le dans les Réglages ou choisis Ollama."
        case .modelNotReady: "Le modèle d'Apple n'est pas encore prêt (téléchargement en cours ?). Réessaie plus tard."
        @unknown default: "Le modèle d'Apple n'est pas disponible sur cet appareil."
        }
    }
}

/// A local Ollama server, through its HTTP API (`POST /api/generate`).
public struct OllamaSummarizer: Summarizer {
    let baseURL: URL
    let model: String
    let session: URLSession

    public init(baseURL: URL, model: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.model = model
        self.session = session
    }

    public func summarize(_ prompt: String) async throws -> String {
        // Local models can take minutes on a long prompt.
        var request = URLRequest(url: baseURL.appending(path: "api/generate"), timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Request(model: model, prompt: prompt, stream: false))
        return try await JSONDecoder().decode(Response.self, from: send(request)).response
    }

    /// Names of the models installed on the server (`GET /api/tags`), sorted.
    public func installedModels() async throws -> [String] {
        let data = try await send(URLRequest(url: baseURL.appending(path: "api/tags"), timeoutInterval: 5))
        return try JSONDecoder().decode(Tags.self, from: data).models.map(\.name).sorted()
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data, response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where [.cannotConnectToHost, .cannotFindHost, .networkConnectionLost,
                                             .notConnectedToInternet, .timedOut].contains(error.code) {
            throw CairnError.ollamaUnreachable
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw http.statusCode == 404 ? CairnError.ollamaModelNotFound(model) : CairnError.httpStatus(http.statusCode)
        }
        return data
    }

    struct Request: Codable, Equatable {
        var model: String
        var prompt: String
        var stream: Bool
    }

    private struct Response: Decodable {
        var response: String
    }

    private struct Tags: Decodable {
        struct Model: Decodable { var name: String }
        var models: [Model]
    }
}
