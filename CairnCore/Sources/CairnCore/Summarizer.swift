import Foundation
import FoundationModels
import Synchronization

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

    static func message(for reason: SystemLanguageModel.Availability.UnavailableReason, language: String? = nil) -> String {
        func l(_ key: String.LocalizationValue) -> String { Localization.string(key, language) }
        return switch reason {
        case .deviceNotEligible: l("This device does not support Apple Intelligence. Choose Ollama in Settings.")
        case .appleIntelligenceNotEnabled: l("Apple Intelligence is turned off. Turn it on in Settings or choose Ollama.")
        case .modelNotReady: l("Apple's model is not ready yet (download in progress?). Try again later.")
        @unknown default: l("Apple's model is not available on this device.")
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

/// Anthropic's Messages API (`POST /v1/messages`), with the user's API key. The articles are sent to Anthropic.
public struct AnthropicSummarizer: Summarizer {
    public static let defaultModel = "claude-haiku-5-5"
    public static let host = "api.anthropic.com"

    let apiKey: String
    let model: String
    let baseURL: URL
    let session: URLSession

    public init(apiKey: String, model: String = AnthropicSummarizer.defaultModel,
                baseURL: URL = URL(string: "https://api.anthropic.com")!, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.session = session
    }

    public func summarize(_ prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw CairnError.anthropicKeyMissing }
        var request = URLRequest(url: baseURL.appending(path: "v1/messages"), timeoutInterval: 300)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")
        // Server-side fallback: when the model's safety classifiers decline, another model answers instead of an error.
        // shortcut: Haiku has no server-side fallback and would reject the field; revisit if that changes.
        let fallbacks = model.contains("haiku") ? nil : "default"
        if fallbacks != nil { request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta") }
        request.httpBody = try JSONEncoder().encode(Request(model: model, maxTokens: 16_000, fallbacks: fallbacks,
                                                            messages: [.init(role: "user", content: prompt)]))

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let error: CairnError = switch http.statusCode {
            case 401, 403: .anthropicKeyInvalid
            case 402: .anthropicBilling
            case 404: .anthropicModelNotFound(model)
            case 429, 529: .anthropicRateLimited
            default: .httpStatus(http.statusCode)
            }
            throw error
        }
        let answer = try JSONDecoder().decode(Response.self, from: data)
        // A refusal is a 200: nothing to read in its content.
        if answer.stopReason == "refusal" { throw CairnError.anthropicRefused }
        // Thinking blocks come first on some models; only the text blocks are the summary.
        let text = answer.content.filter { $0.type == "text" }.compactMap(\.text).joined()
        guard !text.isEmpty else { throw CairnError.summarizerUnavailable(Localization.string("Claude returned no text.")) }
        return text
    }

    struct Request: Codable, Equatable {
        struct Message: Codable, Equatable {
            var role: String
            var content: String
        }
        var model: String
        var maxTokens: Int
        var fallbacks: String?
        var messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model, fallbacks, messages
            case maxTokens = "max_tokens"
        }
    }

    private struct Response: Decodable {
        struct Block: Decodable {
            var type: String
            var text: String?
        }
        var content: [Block]
        var stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
    }
}

/// The user's own Claude Code CLI (`claude -p`), so the summary goes through the account it is logged in with (a Claude
/// plan, no API key). Every tool is off, so an article cannot make it run a command or touch a file. The articles are
/// sent to Anthropic.
public struct ClaudeCodeSummarizer: Summarizer {
    let executable: URL
    let model: String
    let environment: [String: String]
    let timeout: TimeInterval

    /// `model` empty: the CLI's own default.
    public init(executable: URL, model: String = "", environment: [String: String] = ProcessInfo.processInfo.environment,
                timeout: TimeInterval = 300) {
        self.executable = executable
        self.model = model
        self.environment = environment
        self.timeout = timeout
    }

    /// An app launched from the Dock does not get the shell's PATH: the usual install places are tried in turn.
    public static func defaultCandidates(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        [home.appending(path: ".local/bin/claude"), URL(filePath: "/opt/homebrew/bin/claude"), URL(filePath: "/usr/local/bin/claude")]
    }

    public static func locate(in candidates: [URL] = defaultCandidates()) -> URL? {
        candidates.first { FileManager.default.isExecutableFile(atPath: $0.path(percentEncoded: false)) }
    }

    public func summarize(_ prompt: String) async throws -> String {
        guard FileManager.default.isExecutableFile(atPath: executable.path(percentEncoded: false)) else {
            throw CairnError.claudeCodeNotFound
        }
        // An empty working folder (no CLAUDE.md or project to pick up), holding the prompt that becomes stdin: a file
        // rather than a pipe, which would kill the app with SIGPIPE if the CLI exits without reading it.
        let folder = FileManager.default.temporaryDirectory.appending(path: "cairn-claude-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let promptFile = folder.appending(path: "prompt.txt")
        try Data(prompt.utf8).write(to: promptFile)

        let process = Process()
        process.executableURL = executable
        process.currentDirectoryURL = folder
        process.arguments = ["-p", "--output-format", "json", "--tools", "", "--strict-mcp-config", "--disable-slash-commands",
                             "--no-session-persistence", "--setting-sources", ""] + (model.isEmpty ? [] : ["--model", model])
        // The CLI must use the logged-in account, not a key the user happens to have exported.
        process.environment = environment.filter { $0.key != "ANTHROPIC_API_KEY" }
        process.standardInput = try FileHandle(forReadingFrom: promptFile)
        process.standardError = FileHandle.nullDevice
        let output = Pipe()
        process.standardOutput = output

        let timeout = timeout
        let (data, status, timedOut) = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, Int32, Bool), Error>) in
                DispatchQueue.global().async {
                    do { try process.run() } catch { continuation.resume(throwing: CairnError.claudeCodeNotFound); return }
                    let flag = Mutex(false)
                    let watchdog = DispatchWorkItem { if process.isRunning { flag.withLock { $0 = true }; process.terminate() } }
                    DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: watchdog)
                    let data = output.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    watchdog.cancel()
                    continuation.resume(returning: (data, process.terminationStatus, flag.withLock { $0 }))
                }
            }
        } onCancel: {
            if process.isRunning { process.terminate() }
        }

        if timedOut { throw CairnError.claudeCodeFailed(Localization.string("timed out (\(Int(timeout)) s)")) }
        // Not logged in exits with 1 but still writes its JSON: the output is read whatever the status.
        guard let answer = try? JSONDecoder().decode(Answer.self, from: data) else {
            throw CairnError.claudeCodeFailed(Localization.string("unreadable response (code \(status))"))
        }
        if answer.isError {
            throw answer.result.contains("Not logged in") || answer.result.contains("/login")
                ? CairnError.claudeCodeNotLoggedIn : CairnError.claudeCodeFailed(answer.result)
        }
        let text = answer.result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CairnError.claudeCodeFailed(Localization.string("empty response")) }
        return text
    }

    private struct Answer: Decodable {
        var isError: Bool
        var result: String

        enum CodingKeys: String, CodingKey {
            case isError = "is_error"
            case result
        }
    }
}
