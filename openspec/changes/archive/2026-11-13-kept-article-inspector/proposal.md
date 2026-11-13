# Proposal

## Why

Le volet du bas qui porte la note et les tags d'un article gardé est peu soigné : il occupe toute la largeur alors que le texte est centré, prend environ 200 points de hauteur même vide, et ses champs sont des rectangles gris faits main. macOS a un modèle standard pour « les infos d'un élément à côté de son contenu » : l'inspecteur à droite (Notes, Finder, Keynote).

## What Changes

- Le volet du bas disparaît. La note et les tags d'un article sont dans un inspecteur à droite du volet de lecture, en formulaire groupé natif.
- Un bouton de la barre d'outils du volet de lecture et le raccourci standard du menu Présentation ouvrent et ferment l'inspecteur ; son état est mémorisé.
- L'inspecteur montre le cairn de l'article (modifiable quand il y en a plusieurs), la date où il a été gardé, les « Notes » (libellé au pluriel) et les tags.
- Les tags sont des capsules aux couleurs système neutres, avec le champ d'ajout et les suggestions existants.
- Pour un article non gardé, l'inspecteur invite à le garder.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `cairn` : nouvel inspecteur d'un article, qui porte la note et les tags.
- `article-reading` : la barre d'outils du volet de lecture gagne le bouton de l'inspecteur, grisé quand le volet n'affiche pas un article.

## Impact

- `App/ArticleDetailView.swift` : `KeptEditor` devient le contenu de l'inspecteur ; le volet du bas est retiré ; bouton dans `ReaderToolbar`.
- `App/CairnApp.swift` : commandes standard de l'inspecteur dans le menu Présentation.
- Aucune donnée ni CairnCore touchés.
