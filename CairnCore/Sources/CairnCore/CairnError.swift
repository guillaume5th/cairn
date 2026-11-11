import Foundation

public enum CairnError: LocalizedError, Equatable {
    case invalidURL
    case httpStatus(Int)
    case notAFeed
    case alreadySubscribed
    case invalidOPML

    public var errorDescription: String? {
        switch self {
        case .invalidURL: "L'adresse saisie n'est pas une URL http(s) valide."
        case let .httpStatus(code): "Le serveur a répondu avec l'erreur HTTP \(code)."
        case .notAFeed: "Cette adresse ne renvoie pas un flux RSS, Atom ou JSON Feed lisible."
        case .alreadySubscribed: "Tu es déjà abonné à ce flux."
        case .invalidOPML: "Ce fichier n'est pas un fichier OPML valide."
        }
    }
}
