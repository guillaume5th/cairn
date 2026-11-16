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
        case .anthropicKeyMissing: "Aucune clé API Anthropic n'est enregistrée. Saisis-la dans les Réglages."
        case .anthropicKeyInvalid: "Anthropic refuse la clé API. Vérifie-la dans les Réglages."
        case .anthropicBilling: "Anthropic signale un problème de facturation sur ce compte API (crédit épuisé ?)."
        case let .anthropicModelNotFound(model): "Le modèle Claude « \(model) » est introuvable ou n'est pas accessible avec cette clé."
        case .anthropicRateLimited: "Anthropic limite les requêtes ou est surchargé pour le moment. Réessaie dans un instant."
        case .anthropicRefused: "Claude a refusé de résumer ce contenu."
        case .claudeCodeNotFound: "La CLI Claude Code est introuvable. Installe-la, ou indique son chemin dans les Réglages."
        case .claudeCodeNotLoggedIn: "Claude Code n'est connecté à aucun compte. Lance « claude » dans un terminal pour te connecter."
        case let .claudeCodeFailed(reason): "Claude Code a échoué : \(reason)"
        case .emptyFeedName: "Le titre de l'abonnement ne peut pas être vide."
        case .emptyTagName: "Le nom du tag ne peut pas être vide."
        case .invalidBackup: "Ce fichier n'est pas une sauvegarde de Cairn lisible."
        case .unsupportedBackup: "Cette sauvegarde vient d'une version plus récente de Cairn. Mets Cairn à jour pour la restaurer."
        }
    }
}
