# Proposal

## Why

Certains flux sont protégés par un identifiant et un mot de passe (flux privés, intranet, services payants, auto-hébergés). Cairn ne sait pas les lire : l'ajout échoue sur « erreur HTTP 401 ».

## What Changes

- Quand un serveur demande une authentification à l'ajout d'un abonnement, Cairn demande un identifiant et un mot de passe, puis réessaie.
- « Identifiants… » dans le menu contextuel d'un abonnement, pour les saisir, les changer ou les retirer (identifiant vide).
- Les identifiants sont rangés dans le trousseau macOS, par site (hôte), et envoyés en authentification HTTP Basic à chaque requête vers ce site (flux, page complète, icône).
- Une erreur 401 se lit « Ce site demande un identifiant et un mot de passe. »
- Les identifiants ne font pas partie de la sauvegarde.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `feed-subscriptions` : abonnements à des flux protégés.

## Impact

- `CairnCore` : `FeedFetcher` reçoit une fonction qui fournit les identifiants d'un hôte ; message de `httpStatus(401)`.
- Nouveau `App/Credentials.swift` (trousseau), `App/AppState.swift`, `App/ContentView.swift` (alerte), `App/SidebarView.swift` (menu).
