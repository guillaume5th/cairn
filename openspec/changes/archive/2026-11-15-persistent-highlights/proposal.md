# Proposal

## Why

« Surligner » ne laisse aucune trace dans l'article : en le rouvrant, on ne voit pas ce qu'on avait retenu, alors que le mot promet une surbrillance. Et l'action n'existe que dans le menu Édition (⇧⌘H), où il faut la chercher.

## What Changes

- Les passages cités dans la note (blocs `> …`) restent surlignés dans l'article, d'une couleur distincte de celle de la recherche. La note reste la seule source : effacer ou modifier une citation retire sa surbrillance, sans rien stocker de plus.
- Un bouton « Surligner » (surligneur) rejoint la barre d'outils du lecteur, avec la même règle que le menu : direct avec un cairn ou sur un article gardé, menu des cairns sinon. Il est grisé sans article, comme les autres boutons de lecture.
- Une note vide indique le geste : « Sélectionnez un passage puis ⇧⌘H pour le citer ici ».
- Remplace l'exigence « le passage MUST NOT rester surligné dans l'article ».

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `cairn` : les passages cités restent surlignés dans l'article ; « Surligner » dans la barre d'outils ; indication dans la note vide.

## Impact

- `CairnCore/Sources/CairnCore/Library.swift` : extraction des citations d'une note (fonction pure, testée).
- `App/HTMLView.swift` : script qui surligne les citations dans la page, à travers les nœuds texte.
- `App/ArticleDetailView.swift` : passe les citations au lecteur, bouton dans `ReaderToolbar` (et sa version grisée), indication dans la note de `KeptEditor`.
- Pas de changement de modèle ni de migration.
