import Foundation

public enum CairnError: LocalizedError, Equatable {
    case invalidURL
    case httpStatus(Int)
    case notAFeed
    case noFeedFound
    case noArticleContent
    case alreadySubscribed
    case invalidOPML
    case emptyFolderName
    case duplicateFolder
    case emptyCairnName
    case duplicateCairn
    case lastCairn
    case ollamaUnreachable
    case ollamaModelNotFound(String)
    case summarizerUnavailable(String)
    case anthropicKeyMissing
    case anthropicKeyInvalid
    case anthropicBilling
    case anthropicModelNotFound(String)
    case anthropicRateLimited
    case anthropicRefused
    case claudeCodeNotFound
    case claudeCodeNotLoggedIn
    case claudeCodeFailed(String)
    case invalidBackup
    case emptyFeedName
    case emptyTagName
    case unsupportedBackup

    public var errorDescription: String? { message() }

    func message(language: String? = nil) -> String {
        func l(_ key: String.LocalizationValue) -> String { Localization.string(key, language) }
        return switch self {
        case .invalidURL: l("The address you entered is not a valid http(s) URL.")
        case .httpStatus(401): l("This site requires a username and password.")
        case let .httpStatus(code): l("The server answered with HTTP error \(code).")
        case .notAFeed: l("This address does not return a readable RSS, Atom or JSON Feed.")
        case .noFeedFound: l("No RSS, Atom or JSON Feed was found on this site. Try the exact address of its feed.")
        case .noArticleContent: l("No article text was found on this page.")
        case .alreadySubscribed: l("You are already subscribed to this feed.")
        case .invalidOPML: l("This file is not a valid OPML file.")
        case .emptyFolderName: l("The folder name cannot be empty.")
        case .duplicateFolder: l("A folder with this name already exists.")
        case .emptyCairnName: l("The cairn name cannot be empty.")
        case .duplicateCairn: l("A cairn with this name already exists.")
        case .lastCairn: l("The last cairn cannot be deleted.")
        case .ollamaUnreachable: l("The Ollama server is unreachable. Check that it is running and its address in Settings.")
        case let .ollamaModelNotFound(model): l("The Ollama model “\(model)” was not found. Install it with “ollama pull \(model)”.")
        case let .summarizerUnavailable(reason): reason
        case .anthropicKeyMissing: l("No Anthropic API key is saved. Enter it in Settings.")
        case .anthropicKeyInvalid: l("Anthropic rejects the API key. Check it in Settings.")
        case .anthropicBilling: l("Anthropic reports a billing problem on this API account (out of credit?).")
        case let .anthropicModelNotFound(model): l("The Claude model “\(model)” was not found or is not available with this key.")
        case .anthropicRateLimited: l("Anthropic is rate limiting requests or is overloaded right now. Try again in a moment.")
        case .anthropicRefused: l("Claude refused to summarize this content.")
        case .claudeCodeNotFound: l("The Claude Code CLI was not found. Install it, or give its path in Settings.")
        case .claudeCodeNotLoggedIn: l("Claude Code is not signed in to any account. Run “claude” in a terminal to sign in.")
        case let .claudeCodeFailed(reason): l("Claude Code failed: \(reason)")
        case .emptyFeedName: l("The subscription title cannot be empty.")
        case .emptyTagName: l("The tag name cannot be empty.")
        case .invalidBackup: l("This file is not a readable Cairn backup.")
        case .unsupportedBackup: l("This backup comes from a newer version of Cairn. Update Cairn to restore it.")
        }
    }
}
