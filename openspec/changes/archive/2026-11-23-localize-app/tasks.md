# Tasks

## 1. Configuration

- [x] 1.1 Passer `developmentLanguage` à `en` dans `project.yml`, régénérer avec `xcodegen` et vérifier que `project.pbxproj` a `developmentRegion = en` et `knownRegions` avec `en` et `fr`
- [x] 1.2 Ajouter `defaultLocalization: "en"` et la ressource `Localizable.xcstrings` (vide) à `CairnCore/Package.swift`, et vérifier que `swift build` dans `CairnCore` passe

## 2. CairnCore

- [x] 2.1 Réécrire en anglais avec `String(localized:bundle: .module)` les textes de `CairnError`, `Summarizer` (indisponibilité, erreurs Claude), `SearchToken`, `CairnExport`, ajouter les traductions fr (texte actuel) au catalog, adapter `CairnExportTests` et `SearchTokenTests` à l'anglais et vérifier que `swift test` passe
- [x] 2.2 Passer `Library.digestPrompt` et `articleSummaryPrompt` en anglais avec un paramètre `language` (défaut : `Bundle.module.preferredLocalizations.first`) qui ajoute « Write the summary in French/English. », ajouter un test par langue et vérifier que `swift test` passe

## 3. App

- [x] 3.1 Réécrire en anglais les littéraux SwiftUI de `ArticleDetailView`, `ContentView`, `SidebarView`, `DigestViews`, `CairnApp` (menus, réglages, alertes, aides) et vérifier que la compilation d'Xcode les extrait dans `App/Localizable.xcstrings`
- [x] 3.2 Passer à `String(localized:)` les textes construits en `String` (`AppState.message`, `DigestNotifications`, ternaires, `Backups`, `Updates`, noms de fichiers d'export), trouvés par grep (`? "`, `= "`, `.title =`), et vérifier qu'aucun texte français ne reste dans `App/*.swift` (`grep -n '"[^"]*[éèàêçù][^"]*"' App/*.swift` vide, hors données)
- [x] 3.3 Remplacer les ternaires de pluriel (articles sélectionnés, supprimer N articles, retirer du cairn, nouveaux articles) par une clé interpolée avec variations de pluriel fr/en dans le catalog, et vérifier « 1 article sélectionné » / « 3 articles sélectionnés » dans Cairn Dev
- [x] 3.4 Renseigner toutes les traductions fr dans `App/Localizable.xcstrings` (reprises du texte actuel) et vérifier que le catalog n'a aucune clé à l'état « new » ou « needs review »

## 4. Vérification

- [x] 4.1 Lancer `/cairn-check` (tests CairnCore et build Xcode) et vérifier qu'il passe
- [x] 4.2 Lancer Cairn Dev avec `-AppleLanguages "(en)"` puis `"(fr)"` et `"(de)"` (`/cairn-run`), parcourir sidebar, liste, article, inspecteur, réglages et menus, et vérifier : anglais, français, anglais
- [x] 4.3 Mettre à jour le README s'il décrit l'app comme française uniquement, et vérifier le rendu

## Workflow follow-up

- `/opsx:archive`, commit `feat:`, puis cocher l'idée dans l'issue #20 (`/cairn-idea done`).
