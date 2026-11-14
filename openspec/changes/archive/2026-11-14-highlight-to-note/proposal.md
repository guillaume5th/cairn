# Proposal

## Why

Ce qui vaut la peine d'être retenu dans un article tient souvent en une phrase. Aujourd'hui il faut la copier puis la coller à la main dans la note de l'inspecteur : retenir un passage doit tenir en un geste.

## What Changes

- Dans le volet de lecture, sélectionner du texte puis choisir « Surligner » (menu Édition, ⇧⌘H) ajoute le passage en citation Markdown (`> passage`) à la fin de la note de l'article.
- Un article non gardé est d'abord gardé : directement quand il n'existe qu'un cairn, dans le cairn choisi sinon (« Surligner dans »).
- Pas de surbrillance persistante dans l'article : la note est la seule trace.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `cairn` : citer un passage de l'article dans sa note.

## Impact

- `CairnCore/Sources/CairnCore/Library.swift` : ajout d'une citation à une note (fonction pure, testée).
- `App/HTMLView.swift` : lecture de la sélection du `WebPage`.
- `App/CairnApp.swift` : « Surligner » dans le menu Édition, ⇧⌘H.
- `App/ArticleDetailView.swift` : relie l'action à l'article affiché et aux cairns.
- Spotlight suit sans changement (la note est déjà indexée).
