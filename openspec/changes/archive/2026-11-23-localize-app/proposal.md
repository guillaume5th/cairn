# Proposal

## Why

Cairn n'existe qu'en français : `developmentLanguage` vaut `fr` et tous les textes sont écrits en dur en français, dans l'app comme dans les erreurs de CairnCore. Un utilisateur dont le système n'est pas en français ne peut pas utiliser l'app dans sa langue. On veut suivre la langue de macOS : français si le système est en français, anglais sinon.

## What Changes

- L'interface (menus, boutons, aides, alertes, réglages, notifications, messages d'erreur) s'affiche en français quand la langue préférée du système est le français, et en anglais pour toute autre langue.
- La langue source du code passe au français → anglais : les textes du code sont réécrits en anglais, `developmentLanguage` passe à `en`, et un String Catalog (`Localizable.xcstrings`) porte les traductions françaises. Même chose dans CairnCore (`defaultLocalization: "en"`, catalog dans `Bundle.module`).
- Les résumés d'article et le digest quotidien sont rédigés dans la langue de l'app (au lieu de toujours en français).
- L'export Markdown d'un cairn suit la langue de l'app.
- Les données déjà enregistrées (noms de cairns, dossiers, tags, résumés déjà produits) restent telles quelles.

## Capabilities

### New Capabilities
- `app-language` : choix de la langue de l'interface selon la langue du système (français ou anglais, anglais par défaut).

### Modified Capabilities
- `article-summary` : le résumé est rédigé dans la langue de l'app, plus toujours en français.
- `daily-digest` : le digest est rédigé dans la langue de l'app, plus toujours en français.

## Impact

- `project.yml` (`developmentLanguage: en`) et le projet Xcode régénéré (`knownRegions` en et fr).
- Tous les fichiers de `App/` qui contiennent des textes visibles (~110 textes), dont `DigestNotifications.swift`.
- CairnCore : `Package.swift` (`defaultLocalization`), `CairnError`, `Summarizer` (messages d'indisponibilité), `SearchToken`, `CairnExport`, prompts de `Library.digestPrompt` et `Library.articleSummaryPrompt`.
- Tests CairnCore qui comparent des textes français (`CairnExportTests`, `SearchTokenTests`, etc.).
- Aucune nouvelle dépendance.
