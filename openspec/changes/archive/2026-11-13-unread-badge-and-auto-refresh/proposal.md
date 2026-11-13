# Proposal

## Why

Cairn ne récupère les flux qu'au lancement et sur ⌘R : laissé ouvert toute la journée, il n'affiche plus les nouveaux articles tant qu'on ne pense pas à rafraîchir. Et rien n'indique hors de la fenêtre qu'il y a des articles à lire, alors que l'app reste dans le Dock fenêtre fermée.

## What Changes

- Rafraîchissement automatique de tous les abonnements tant que Cairn tourne, fenêtre ouverte ou fermée. Fréquence réglable dans les Réglages : Jamais, 15 min, 30 min, 1 h, 2 h ; 30 min par défaut.
- L'intervalle part du dernier rafraîchissement, quel qu'il soit (lancement, ⌘R ou automatique). Un rafraîchissement automatique n'est jamais lancé pendant qu'un autre est en cours.
- Badge sur l'icône du Dock avec le nombre d'articles non lus, le même que celui de « Tous les articles ». Pas de badge à zéro.
- Interrupteur « Badge sur l'icône » dans Réglages > Affichage, activé par défaut.
- macOS n'affiche le badge qu'avec l'autorisation des pastilles : Cairn la demande au premier lancement (badge activé par défaut), dans la même demande que les notifications du résumé, et les Réglages signalent un refus.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `feed-fetching` : nouveau rafraîchissement automatique et son réglage de fréquence.
- `article-reading` : badge du nombre de non-lus sur l'icône du Dock et son réglage.

## Impact

- `App/AppState.swift` : date du dernier rafraîchissement, boucle de rafraîchissement automatique lancée par `launch()`, mise à jour du badge après chaque rafraîchissement.
- `App/DigestViews.swift` (`SettingsView`) : choix de la fréquence et interrupteur du badge.
- `App/DigestNotifications.swift` : la demande d'autorisation inclut les pastilles.
- `App/SidebarView.swift` : met à jour le badge quand le nombre de non-lus change (lecture, marquage).
- Aucun impact sur `CairnCore` ni sur les données stockées ; deux nouvelles clés de préférences.
