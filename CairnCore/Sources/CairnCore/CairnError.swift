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
    case invalidBackup
    case emptyFeedName
    case emptyTagName
    case unsupportedBackup

    public var errorDescription: String? {
        switch self {
        case .invalidURL: "L'adresse saisie n'est pas une URL http(s) valide."
        case .httpStatus(401): "Ce site demande un identifiant et un mot de passe."
        case let .httpStatus(code): "Le serveur a répondu avec l'erreur HTTP \(code)."
        case .notAFeed: "Cette adresse ne renvoie pas un flux RSS, Atom ou JSON Feed lisible."
        case .noFeedFound: "Aucun flux RSS, Atom ou JSON Feed n'a été trouvé sur ce site. Essaie l'adresse exacte de son flux."
        case .noArticleContent: "Aucun texte d'article n'a été trouvé sur cette page."
        case .alreadySubscribed: "Tu es déjà abonné à ce flux."
        case .invalidOPML: "Ce fichier n'est pas un fichier OPML valide."
        case .emptyFolderName: "Le nom du dossier ne peut pas être vide."
        case .duplicateFolder: "Un dossier porte déjà ce nom."
        case .emptyCairnName: "Le nom du cairn ne peut pas être vide."
        case .duplicateCairn: "Un cairn porte déjà ce nom."
        case .lastCairn: "Le dernier cairn ne peut pas être supprimé."
        case .ollamaUnreachable: "Le serveur Ollama est injoignable. Vérifie qu'il tourne et son adresse dans les Réglages."
        case let .ollamaModelNotFound(model): "Le modèle Ollama « \(model) » est introuvable. Installe-le avec « ollama pull \(model) »."
        case let .summarizerUnavailable(reason): reason
        case .emptyFeedName: "Le titre de l'abonnement ne peut pas être vide."
        case .emptyTagName: "Le nom du tag ne peut pas être vide."
        case .invalidBackup: "Ce fichier n'est pas une sauvegarde de Cairn lisible."
        case .unsupportedBackup: "Cette sauvegarde vient d'une version plus récente de Cairn. Mets Cairn à jour pour la restaurer."
        }
    }
}
