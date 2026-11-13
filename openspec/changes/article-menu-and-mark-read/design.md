# Design

## Context

Le menu contextuel d'un article est construit par `ArticleMenuItems`. Les commandes de la barre des menus (`CairnCommands`) n'ont pas accès à la sélection de la liste ni aux confirmations (retirer du cairn, ouvrir plus de 10 articles, supprimer) que présente la liste. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Un seul composant pour le menu contextuel d'un article et le menu « Article », pour qu'ils ne divergent pas.

**Non-Goals:**
- Raccourcis pour Partager, Copier le lien ou Supprimer.
- Menu contextuel pour les tags, qui demande de pouvoir renommer ou retirer un tag partout : à proposer à part.

## Decisions

- **`ArticleMenuItems` sert aux deux menus.** Ses raccourcis apparaissent donc aussi dans le menu contextuel, comme dans Mail. Avec une liste vide, toutes ses actions sont grisées et Partager et Supprimer disparaissent.
- **La liste publie sa sélection par `focusedSceneValue(\.articleSelection)`** : les articles sélectionnés (l'article affiché seul, ou la sélection) et les liaisons de ses confirmations. Le menu « Article » (`ArticleCommands`) lit cette valeur ; la liste garde les confirmations. Sans liste d'articles (Résumés), la valeur est absente et le menu est grisé. Alternative écartée : passer la sélection par `AppState`, qui aurait dupliqué l'état de la vue.
- **Le menu reçoit le `ModelContext` explicitement** (`.modelContext`) : `KeepButton` interroge les cairns, et les commandes sont hors du conteneur de la fenêtre.
- **Raccourcis ⇧⌘L et ⇧⌘U**, ceux de Signaler et Marquer comme non lu dans Mail ; **⌘↩** pour ouvrir dans le navigateur.
- **« Copier le lien » écrit du texte brut** (`NSPasteboard`, un lien par ligne), qui se colle partout.
- **« Marquer tout comme lu » dans la barre latérale** parcourt les articles des abonnements visés ; grisé via `unreadCount`, déjà calculé pour les badges.
- **Partager sans icône dans les menus** (`labelStyle(.titleOnly)`), comme les autres actions.

## Risks / Trade-offs

- [⌘↩ pourrait entrer en conflit avec un futur raccourci] → aucun autre usage dans l'app aujourd'hui.
- [Pas de test automatisé de l'interface] → vérification manuelle dans l'app, voir tasks.md.
