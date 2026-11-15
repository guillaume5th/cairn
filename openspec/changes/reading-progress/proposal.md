# Proposal

## Why

Dans un long article, rien n'indique où l'on en est : la barre de défilement de macOS est masquée tant qu'on ne fait pas défiler. Une barre de progression donne la longueur restante d'un coup d'œil.

## What Changes

- Une fine barre de progression sous l'en-tête de l'article, au-dessus du résumé, qui suit le défilement : vide en haut de l'article, pleine en bas.
- Absente quand l'article tient entièrement dans le volet.
- Rien n'est mémorisé : en rouvrant l'article, la lecture reprend en haut, comme aujourd'hui.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : barre de progression de lecture dans le volet de lecture.

## Impact

- `App/HTMLView.swift` : lecture de la géométrie de défilement du `WebView`.
- `App/ArticleDetailView.swift` : affichage de la barre sur le séparateur sous l'en-tête.
- Pas de changement de modèle, pas de JavaScript supplémentaire.
