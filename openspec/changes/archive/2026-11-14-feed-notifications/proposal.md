# Proposal

## Why

Certains abonnements publient rarement mais comptent (un blog d'ami, des annonces de sécurité, une sortie de version). On veut le savoir sans ouvrir Cairn, sans être dérangé par les flux bavards.

## What Changes

- « Notifier les nouveaux articles » dans le menu contextuel des abonnements (un ou plusieurs), désactivé par défaut.
- Après un rafraîchissement, chaque abonnement notifié qui a reçu des articles poste une notification : le nom de l'abonnement, et le titre de l'article ou le nombre d'articles. Un clic ouvre l'abonnement.
- Rien n'est notifié à l'ajout d'un abonnement (ses articles ne sont pas « nouveaux »).
- Le réglage fait partie de la sauvegarde.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `feed-fetching` : notification des nouveaux articles par abonnement.
- `backup` : le réglage de notification est sauvegardé et restauré.

## Impact

- `CairnCore` : `Feed.notifiesNewArticles` (défaut `false`, compatible CloudKit), `Library.refreshAll` renvoie les articles ajoutés par abonnement, `Backup.FeedEntry.notifiesNewArticles` (optionnel pour lire les anciennes sauvegardes).
- `App/SidebarView.swift` (menu), `App/AppState.swift` (notifications après rafraîchissement), `App/DigestNotifications.swift` (contenu et clic), `App/ContentView.swift` (ouverture de l'abonnement).
