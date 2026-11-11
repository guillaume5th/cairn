# Tasks

## 1. Outillage et squelette

- [x] 1.1 Installer Xcode (action utilisateur) puis `sudo xcode-select -s /Applications/Xcode.app` ; vérifier que `xcodebuild -version` répond
- [x] 1.2 Installer XcodeGen (`brew install xcodegen`) ; vérifier que `xcodegen --version` répond
- [x] 1.3 Créer le package local `CairnCore` (macOS 27, dépendance FeedKit, cible de tests Swift Testing) ; vérifier que `swift build` puis `swift test` passent dans `CairnCore/`
- [x] 1.4 Écrire `project.yml` (cible app `Cairn`, macOS 27, Swift 6, dépendance au package local, App Sandbox + entitlements réseau client et fichiers choisis par l'utilisateur), une `App` SwiftUI vide avec `ModelContainer`, et ignorer `*.xcodeproj` dans `.gitignore` ; vérifier que `xcodegen && xcodebuild -scheme Cairn build` réussit et que l'app s'ouvre
- [x] 1.5 Compléter le README (prérequis Xcode/XcodeGen, `xcodegen`, `swift test`, build) ; vérifier que les commandes documentées fonctionnent telles quelles

## 2. Modèle de données

- [x] 2.1 Définir les modèles SwiftData `Feed`, `Article`, `Tag` dans `CairnCore` selon le design (aucun `.unique`, relations optionnelles, `sourceTitle` dupliqué, `Tag.key` normalisé) ; vérifier avec un test qu'un `ModelContainer` en mémoire s'initialise et qu'un aller-retour insertion/lecture fonctionne
- [x] 2.2 Implémenter la suppression d'un abonnement (supprime ses articles non gardés, détache les gardés) ; vérifier par un test que l'article gardé survit avec son `sourceTitle`

## 3. Récupération des flux

- [x] 3.1 Implémenter le parsing `Data -> ParsedFeed` via FeedKit (titre, items avec externalID = guid/id sinon lien, lien, date, contenu sinon résumé) ; vérifier avec des fixtures RSS 2.0, Atom et JSON Feed, y compris un item sans date et un item sans guid
- [x] 3.2 Implémenter `FeedFetcher` (URLSession, TaskGroup limité à 6, résultat ou erreur par flux) ; vérifier par un test avec un `URLProtocol` factice qu'un flux en erreur n'empêche pas les autres
- [x] 3.3 Implémenter l'ingestion (dédoublonnage par flux + externalID, date de récupération si pas de date, filtre de rétention, `lastError` renseigné ou effacé) ; vérifier par des tests que deux ingestions identiques ne créent aucun doublon et préservent lu/gardé/note/tags, et qu'un item de plus de 30 jours est ignoré
- [x] 3.4 Implémenter l'ajout d'abonnement par URL (fetch + parse avant enregistrement, titre du flux, refus d'un doublon d'URL) ; vérifier par des tests les cas valide, invalide et doublon

## 4. OPML

- [x] 4.1 Implémenter le parseur OPML (`XMLParser`, outlines imbriqués aplatis, seuls ceux avec `xmlUrl`, erreur si fichier invalide) ; vérifier avec des fixtures avec et sans dossiers, et une fixture invalide
- [x] 4.2 Implémenter l'import (création des abonnements manquants, comptes ajoutés/ignorés) et le générateur OPML 2.0 ; vérifier par un test d'export puis réimport dans une base vide qui recrée les mêmes abonnements, et qu'un réimport n'ajoute rien

## 5. Rétention et recherche

- [x] 5.1 Implémenter `Retention` (30 jours) et la purge des articles non gardés ; vérifier par un test qu'un article ancien non gardé est supprimé et qu'un article ancien gardé est conservé
- [x] 5.2 Implémenter garder / ne plus garder (`keptAt`), les tags (création ou réutilisation par `key`, insensibles à la casse) et la recherche en mémoire (titre, contenu, note, tags, `localizedStandardContains`) ; vérifier par des tests « Swift »/« swift » = un seul tag, une recherche qui ne trouve que dans la note, et « deploiement » qui trouve « Déploiement »

## 6. Interface

- [x] 6.1 Construire le `NavigationSplitView` : barre latérale (Tous les articles, Cairn + tags, abonnements avec non lus et indicateur d'erreur), liste d'articles triée avec filtre Non lus ; vérifier à la main avec deux abonnements réels
- [x] 6.2 Construire le panneau de lecture (`WebView` SwiftUI sans JS, CSP du design, liens ouverts dans le navigateur, état vide « aucun contenu »), marquage lu à l'affichage, « marquer non lu », « tout marquer comme lu », bouton « Ouvrir dans le navigateur » ; vérifier à la main qu'un lien du contenu ouvre le navigateur et qu'un `<script>` du flux ne s'exécute pas
- [x] 6.3 Ajouter les commandes de menu : Ajouter un flux (feuille avec saisie d'URL et erreurs), Importer / Exporter OPML (`fileImporter`/`fileExporter`), Rafraîchir ⌘R avec indicateur et protection contre le double déclenchement ; vérifier à la main chaque commande
- [x] 6.4 Câbler le lancement : purge puis rafraîchissement en tâche non bloquante ; vérifier à la main que l'interface reste utilisable pendant le rafraîchissement
- [x] 6.5 Construire la vue Cairn : liste triée par `keptAt`, filtre par tag, `.searchable`, éditeur de note enregistré automatiquement, saisie de tags avec suggestions, confirmation avant de retirer un article annoté ; vérifier à la main une note qui persiste après relance

## 7. Vérification d'ensemble

- [x] 7.1 Parcours complet sur une base vide : importer un OPML réel (NetNewsWire ou Feedly), ⌘R, lire un article, le garder avec note et tag, le retrouver par recherche, supprimer son abonnement, relancer l'app ; vérifier que l'article gardé, sa note et son tag sont toujours là
- [x] 7.2 Lancer `swift test` dans `CairnCore/` et `xcodebuild -scheme Cairn build` ; vérifier que les deux passent sans avertissement de concurrence

## Workflow follow-up

- Archiver le change une fois la V1 validée (`/opsx:archive`).
