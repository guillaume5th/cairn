# Proposal

## Why

Pour envoyer un article à quelqu'un ou le passer à une autre app (Notes, Messages, Mail), il faut aujourd'hui l'ouvrir dans le navigateur puis le partager depuis là. Le bouton Partager du système devrait être disponible directement dans Cairn.

## What Changes

- Action « Partager » sur un article, dans la barre d'outils du panneau de lecture et dans son menu contextuel. Elle ouvre la feuille de partage du système avec le titre et le lien de l'article.
- Le bouton grisé correspondant rejoint les boutons de lecture affichés quand le panneau n'a pas d'article.
- Mac, iPhone et iPad.
- Pas d'extension de partage : on ne peut pas s'abonner ni garder une page depuis Safari.

## Capabilities

### New Capabilities

- `sharing` : partager un article de Cairn vers d'autres apps.

### Modified Capabilities

- `article-reading` : la liste des boutons grisés du panneau sans article comprend « Partager ».

## Impact

- `App/ArticleDetailView.swift` : `ShareLink` dans la barre d'outils, et un bouton grisé dans `DisabledReaderToolbar`.
- Menu contextuel d'un article (`ArticleMenuItems`).
- Aucune nouvelle cible ni dépendance, et aucun changement de données.
