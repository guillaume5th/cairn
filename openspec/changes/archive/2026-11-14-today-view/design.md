# Design

## Context

La barre latérale liste « Tous les articles » (`SidebarItem.all`) puis les résumés, les cairns et les abonnements. `ContentView.visibleArticles` filtre la requête de tous les articles selon l'entrée choisie. Voir proposal.md.

## Goals / Non-Goals

**Goals:** une vue du jour sans nouveau modèle ni réglage.

**Non-Goals:** vues personnalisables (« les 7 derniers jours », règles) ; vue « Non lus » (le filtre existe déjà).

## Decisions

- **« Aujourd'hui » = publié depuis le début du jour local (`Calendar.startOfDay`).** C'est la date que montre la liste. Alternative écartée : la date de réception, que le modèle ne stocke pas.
- **Nouveau cas `SidebarItem.today`.** Le reste (recherche, filtre, ordre, mémoire de sélection) suit sans code de plus, comme pour `.all`. Ajouter un cas ne casse pas le décodage de la sélection mémorisée.

## Risks / Trade-offs

- [La vue ne change pas d'elle-même à minuit] → elle se recalcule au prochain rafraîchissement ou à la prochaine action ; acceptable pour une liste de lecture.
