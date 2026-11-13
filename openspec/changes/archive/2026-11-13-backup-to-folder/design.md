# Design

## Context

La base SwiftData (`CairnStore`) contient `Feed`, `Folder`, `Cairn`, `Article`, `Tag` et `Digest`. Les réglages sont des clés `UserDefaults` lues par `@AppStorage`. L'app est sandboxée avec `files.user-selected.read-write` et signée ad hoc, sans compte développeur : pas de conteneur iCloud. `AppState.launch()` lance déjà des boucles d'une minute (résumé quotidien, rafraîchissement automatique). L'import OPML (`Library.importOPML`) sert de modèle pour recréer abonnements et dossiers. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Une sauvegarde lisible et complète de ce qui ne peut pas être récupéré depuis les flux.
- Une restauration qui remet l'app dans l'état sauvegardé, testée dans `CairnCore`.

**Non-Goals:**
- Synchronisation entre appareils (le schéma reste compatible CloudKit pour plus tard, sans l'utiliser ici).
- Sauvegarde des résumés quotidiens (ils se refont) et de l'état de l'interface.
- Restauration partielle ou fusion (choix de l'utilisateur : remplacer).
- Chiffrement du fichier : il ne contient ni mot de passe ni clé (l'adresse Ollama est une URL locale).

## Decisions

- **Format : JSON `Codable` versionné**, dans `CairnCore/Backup.swift` : `Backup { version: 1, createdAt, feeds, folders, cairns, articles, settings }`. Abonnements identifiés par leur adresse, dossiers et cairns par leur nom, articles reliés à leur abonnement par son adresse et, s'ils sont gardés, à leur cairn par son nom. Les icônes (`iconData` de l'abonnement, `sourceIconData` d'un article gardé sans abonnement) sont des `Data`, encodées en base64 par `JSONEncoder`. Les réglages sont un dictionnaire de valeurs JSON (`Bool`, `Int`, `Double`, `String`) pour une liste fermée de clés. JSON plutôt que plist ou archive : lisible, et diffable si besoin. Un champ `version` permet de refuser un format futur.
- **Tous les articles sont sauvegardés**, gardés ou non (choix de l'utilisateur : retrouver l'état lu de chacun). Champs : `externalID`, `link`, `title`, `publishedAt`, `content`, `isRead`, `isKept`, `keptAt`, `note`, `sourceTitle`, `sourceIconData`, `feedURL`, `cairn` (nil si non gardé), `tags`, `summary`, `summaryDate`, `summaryEngine`, `fullContent`, `fullContentFetchedAt`, `showsFeedContent`. `externalID` et l'abonnement sont ce qui évite le doublon au rafraîchissement suivant (dédoublonnage par flux existant). Un article non gardé plus ancien que la durée de conservation est purgé au lancement suivant, comme d'habitude.
- **Icône d'un abonnement** : `iconData` et `iconCheckedAt` sont restaurés, pour ne pas dépendre d'une nouvelle recherche qui peut échouer (constaté).
- **Réglages sauvegardés** : `articleTextScale`, `showListIcons`, `showsDockBadge`, `refreshInterval`, `articleSummaryHidden`, `collapsedFolders`, `digestEnabled`, `digestTime`, `digestEngine`, `ollamaURL`, `ollamaModel`, `digestRetentionDays`, `digestNotify`. Exclus : `selectionMemory`, `digestLastAttempt`, et les clés de la sauvegarde elle-même (le signet du dossier ne vaut que sur ce Mac). Une clé absente des réglages actuels n'est pas écrite ; à la restauration, une clé absente du fichier est supprimée, pour revenir à sa valeur par défaut.
- **`Library.makeBackup(context:settings:)` et `Library.restore(_:context:)`** dans `CairnCore`, testés sur une base en mémoire. La restauration supprime tous les `Article`, `Feed`, `Folder`, `Tag` et `Cairn`, puis recrée à partir du fichier ; `Digest` n'est pas touché. Le fichier est décodé et validé entièrement avant toute suppression : un fichier illisible ne modifie rien. Après restauration, `ensureCairn` garantit au moins un cairn, puis l'app sauvegarde le contexte et rafraîchit.
- **Accès au dossier : signet de sécurité à portée de l'app** (`URL.bookmarkData(options: .withSecurityScope)`), stocké dans `UserDefaults` (`backupFolderBookmark`), avec le droit `com.apple.security.files.bookmarks.app-scope`. Choix du dossier par `fileImporter` (`allowedContentTypes: [.folder]`). Chaque écriture fait `startAccessingSecurityScopedResource` / `stop…`. Un signet périmé est recréé quand c'est possible ; illisible, l'erreur est affichée et le choix est à refaire.
- **Écriture** : `Data.write(to:options: .atomic)` vers `Cairn <aaaa-MM-jj HHmm>.json`. Le nom porte la date, ce qui trie et identifie les sauvegardes de Cairn. Après une écriture réussie, les fichiers du dossier de la forme `Cairn ….json` au-delà des 7 plus récents (par nom) sont supprimés ; les autres fichiers ne sont pas regardés.
- **Planification** : clé `backupLastDate`, mise à jour après une écriture réussie. Vérification au lancement, après le premier rafraîchissement, puis dans une boucle d'une minute, comme le résumé : `dossier choisi && (pas de dernière date || maintenant ≥ dernière + 24 h)`. Un échec n'avance pas la date : il est retenté à la minute suivante, ce qui spammerait l'erreur ; donc un échec note aussi `backupLastAttempt` et la boucle attend une heure avant de réessayer.
- **Réglages** : section « Sauvegarde » avec `LabeledContent("Dossier")` (nom du dossier ou « Aucun ») et un bouton « Choisir… », la date de la dernière sauvegarde ou l'erreur en pied de section, « Sauvegarder maintenant » (désactivé sans dossier) et « Restaurer… ». La restauration passe par un `fileImporter` puis une `confirmationDialog` destructive (« Restaurer la sauvegarde du … ? Les abonnements, cairns et réglages actuels seront remplacés. »).
- **La fenêtre est démontée pendant la restauration.** Constaté à l'implémentation : supprimer les modèles pendant que la barre latérale les affiche fait planter l'app (lecture de `Feed.iconData` d'un abonnement supprimé). `AppState.isRestoring` remplace `ContentView` par un indicateur de progression le temps de la restauration ; la fenêtre est ensuite reconstruite, sur « Tous les articles » (la sélection mémorisée, dont les identifiants n'existent plus, est effacée).
- **Le droit d'accès est déclaré dans `project.yml`**, d'où XcodeGen génère `App/Cairn.entitlements`.
- **Réglages appliqués après restauration** : écrits dans `UserDefaults.standard`, que les `@AppStorage` observent ; rien d'autre à faire.

## Risks / Trade-offs

- [Signature ad hoc : un signet à portée de l'app pourrait ne plus se résoudre après une mise à jour de Cairn] → vérifié dans Cairn Dev : un signet créé par un build se résout encore après un nouveau build signé ad hoc. Non vérifié entre deux versions publiées ; si cela arrivait, l'erreur s'affiche dans les Réglages et il suffit de rechoisir le dossier.
- [iCloud Drive peut ne pas avoir téléchargé une sauvegarde ancienne (fichier `.icloud`)] → la restauration passe par la fenêtre du système, qui télécharge le fichier choisi ; l'élagage ne compte que les fichiers `Cairn ….json` présents localement, au pire il en garde plus de 7.
- [Fichier plus gros : tous les articles avec leur contenu et leur texte complet, et les icônes] → la durée de conservation borne les articles non gardés à 30 jours ; quelques Mo pour quelques centaines d'articles, acceptable pour 7 copies.
- [Un article publié depuis la sauvegarde est perdu s'il a quitté le flux] → inhérent à toute restauration ; ceux encore dans le flux reviennent non lus.
- [Pas de test automatisé de l'interface] → `CairnCore` testé (aller-retour sauvegarde → restauration) ; interface vérifiée dans Cairn Dev.
