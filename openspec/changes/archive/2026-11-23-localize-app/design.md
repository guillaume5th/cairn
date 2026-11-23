# Design

## Context

- `project.yml` déclare `developmentLanguage: fr` ; le projet Xcode a `knownRegions = (Base, fr)`. Aucun `.lproj` ni `.xcstrings`.
- Les textes sont des littéraux français : dans les vues SwiftUI (`Text`, `Button`, `Label`, `.help`, `Section`…), mais aussi dans des `String` construites (ternaires `count == 1 ? "…" : "…"`, `message = "… \(error)"`, `content.title` des notifications).
- CairnCore (Swift package, sans `defaultLocalization`) porte des textes visibles : `CairnError.errorDescription`, messages d'indisponibilité de `Summarizer`, libellés de `SearchToken`, `CairnExport`, et les prompts `Library.digestPrompt` / `articleSummaryPrompt` qui imposent « Résume en français ».
- Cible macOS 27, Swift 6, projet généré par XcodeGen.

## Goals / Non-Goals

**Goals:**
- Anglais comme langue source et de repli, français comme traduction, résolus par le système.
- Prompts d'IA dans la langue résolue de l'app.

**Non-Goals:**
- Réglage de langue dans Cairn (macOS le fait déjà par app).
- Autres langues que fr/en.
- Traduire les données de l'utilisateur ou le contenu des articles.
- Localiser les messages d'erreur bruts renvoyés par les moteurs d'IA ou les serveurs (transmis tels quels).

## Decisions

### Langue source anglaise, String Catalog
`developmentLanguage: en` dans `project.yml`, littéraux réécrits en anglais, `App/Localizable.xcstrings` contient les traductions françaises (reprises du texte actuel, donc aucun travail de rédaction en français). Xcode extrait les clés à la compilation (`SWIFT_EMIT_LOC_STRINGS`, actif par défaut).
*Alternative écartée* : garder les clés françaises et ajouter l'anglais en traduction. Une langue tierce retomberait sur la langue de développement (le français), contraire à « anglais par défaut ».

### Textes hors littéraux SwiftUI
Un littéral passé directement à `Text`/`Button`/`Label` devient un `LocalizedStringKey` et se traduit seul. Ce n'est pas le cas d'une `String` : ternaires, variables, `content.title`, `message`. Ces sites passent à `String(localized:)`. Les ternaires de pluriel sont remplacés par une seule clé avec interpolation (`"\(count) articles selected"`) et une variation de pluriel dans le catalog, ce qui supprime le ternaire.

### CairnCore localisé dans son propre bundle
`defaultLocalization: "en"` dans `CairnCore/Package.swift`, `Sources/CairnCore/Localizable.xcstrings` en ressource, `String(localized: "…", bundle: .module)` dans `CairnError`, `Summarizer`, `SearchToken`, `CairnExport`. L'app garde ainsi un seul point de vérité par texte, sans faire remonter les erreurs dans l'app.

### Langue des prompts
Les prompts restent en anglais (les modèles suivent bien une consigne anglaise) et se terminent par la langue cible : `Write the summary in French.` ou `in English.`. La langue vient de `Bundle.module.preferredLocalizations.first` dans CairnCore : même résolution que l'app, puisque l'app et le package déclarent les mêmes langues (en, fr). Les fonctions de prompt prennent un paramètre `language` avec ce défaut, pour que les tests fixent la langue sans dépendre du système.
*Alternative écartée* : garder deux prompts entiers (fr et en). Doublon à maintenir pour rien.

### Tests
Les tests qui comparent des textes (`CairnExportTests`, `SearchTokenTests`, prompts) vérifient la version anglaise (source). Le processus de test n'a pas de langue française forcée, donc `String(localized:)` renvoie la source anglaise. Un test vérifie que le prompt contient « in French » quand `language: "fr"`.

## Risks / Trade-offs

- [Gros diff mécanique : ~140 textes à réécrire, risque d'en oublier un ou de casser une traduction] → l'éditeur de catalog d'Xcode signale les clés sans traduction fr ; vérification visuelle de Cairn Dev en anglais et en français (`-AppleLanguages "(en)"` / `"(fr)"`).
- [Une clé non extraite (texte passé comme `String`) reste en anglais en français] → revue des `String` construites par grep (`? "`, `= "`, `.title =`) pendant la mise en œuvre.
- [Clés réécrites : un texte français actuel mal relié à sa clé anglaise] → la traduction française reprend le texte d'origine, vérifiable écran par écran.
- [Les noms de cairns par défaut (« Cairn ») et les exports déjà faits] → « Cairn » est identique dans les deux langues ; rien n'est migré.

## Migration Plan

Aucune donnée à migrer. Régénérer le projet (`xcodegen`) après le changement de `project.yml`. Retour arrière : revert du commit.
