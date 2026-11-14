# Proposal

## Why

Lire ses flux au clavier est le geste central d'un lecteur de flux : passer au prochain article non lu sans viser la liste à la souris. Cairn n'a que les flèches de la liste, qui s'arrêtent sur chaque article, lu ou non.

## What Changes

- Dans la liste d'articles, Espace ou N ouvre le prochain article non lu de la liste affichée, après l'article courant ; au-delà du dernier, la recherche reprend en haut. La liste défile jusqu'à lui et il est marqué comme lu, comme un clic.
- Sans article non lu, un son d'alerte signale qu'il n'y a rien à lire.
- Inchangé : dans l'article, Espace fait défiler la page (WebKit) ; dans un champ de texte, Espace tape un espace.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : aller au prochain non lu au clavier.

## Impact

- `CairnCore` : `Library.nextUnread(after:in:)`, testé.
- `App/ContentView.swift` : touche dans `ArticleListView`, défilement de la liste.
