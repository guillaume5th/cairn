# Tasks

## 1. Projet et configuration

- [x] 1.1 Retirer la cible `Cairn iOS` de `project.yml` (et le commentaire sur les schémas partagés devenu sans objet), puis vérifier que `xcodegen` réussit et que `xcodebuild -list` ne liste plus que le schéma `Cairn`
- [x] 1.2 Supprimer `iOS/Info.plist` et `Config/Signing.xcconfig`, retirer `Config/Local.xcconfig` du `.gitignore`, et vérifier que `grep -rn "Signing.xcconfig\|iOS/Info.plist" project.yml` ne renvoie rien

## 2. Code de l'app

- [x] 2.1 Supprimer `App/BackgroundRefresh.swift`, `AppState.runInBackground` et les `.backgroundTask`/`scenePhase` de `CairnApp.swift` ; retirer `inBackground` de `makeDigest` si plus aucun appelant Mac ne le passe à `true`
- [x] 2.2 Dans `AppState`, `CairnApp`, `DigestNotifications`, `DigestViews`, `HTMLView`, `SidebarView`, `SourceIcon` : garder la branche macOS sans directive et supprimer les branches iOS (imports UIKit compris)
- [x] 2.3 Dans `ContentView` et `ArticleDetailView` : supprimer navigation empilée, `horizontalSizeClass`, tirer pour rafraîchir, wrappers de partage iPad/UIKit ; garder la branche macOS sans directive
- [x] 2.4 Vérifier que `grep -rnE "os\((iOS|macOS)\)|UIKit|UIApplication|horizontalSizeClass|BGTask|iPhone|iPad" App` ne renvoie rien et que `xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build` réussit sans nouvel avertissement
- [x] 2.5 Vérifier que `cd CairnCore && swift test` passe toujours

## 3. Documentation et specs

- [x] 3.1 Retirer du `README.md` le prérequis iOS, la commande de build simulateur, la section « iPhone et iPad » et la mention « sur iOS » de la section Abonnements ; décrire `App/` comme l'app Mac ; vérifier que `grep -nE "iOS|iPhone|iPad" README.md` ne renvoie rien

## 4. Vérification de l'app Mac

- [x] 4.1 Lancer `build/Build/Products/Debug/Cairn.app` et vérifier : ajout d'un abonnement (par l'adresse d'un site), lecture, mode sélection et ses actions sous la liste, partage, article complet, résumé d'article, résumé quotidien « maintenant », Réglages (Affichage compris), fermeture de la fenêtre sans quitter l'app

## Workflow follow-up

- Signaler à l'utilisateur que `Config/Local.xcconfig` (non versionné, identifiant d'équipe) peut être supprimé de son disque.
- Archiver le change (`/opsx:archive`), puis supprimer le dossier `openspec/specs/ios-app` resté sans exigence.
