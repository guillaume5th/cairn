# Design

## Context

Les articles gardés sont en SwiftData ; `AppState` enregistre le contexte principal (`save()` et autosave). La vue d'un cairn est l'entrée `SidebarItem.cairn`, l'article affiché celui de `SelectionMemory.articles`. Voir proposal.md.

## Goals / Non-Goals

**Goals:** retrouver un article gardé depuis Spotlight et l'ouvrir dans Cairn.

**Non-Goals:** indexer les articles non gardés ou le texte complet ; réglage d'activation ; mise à jour incrémentale.

## Decisions

- **Réindexation complète, après chaque enregistrement, seulement si les articles gardés ont changé.** On écoute `ModelContext.didSave`, on attend 2 s (les enregistrements arrivent en rafale), on calcule une empreinte des champs indexés et on remplace tout l'index si elle a changé. Quelques centaines d'articles : simple et sans état à synchroniser. Alternative écartée : suivre chaque garde, retrait, note et tag, au risque d'en oublier un.
- **Identifiant Spotlight = lien de l'article.** Il survit à une restauration (contrairement à l'identifiant SwiftData) et suffit à retrouver l'article gardé.
- **Ouverture par le délégué de l'app (`application(_:continue:)`)**, qui transmet le lien à `AppState` ; `ContentView` sélectionne le cairn et l'article, comme l'ouverture d'un résumé depuis une notification. `onContinueUserActivity` de SwiftUI n'est pas appelé pour une scène `Window`.

## Risks / Trade-offs

- [Deux articles gardés avec le même lien] → un seul résultat ; rare (deux abonnements au même site).
- [Cairn Dev et Cairn ont chacun leur index] → normal, identifiants d'app différents.
