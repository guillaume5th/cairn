# Proposal

## Why

Le titre d'un abonnement vient du flux et ne se change pas, alors que beaucoup de flux ont un titre long ou peu parlant. Et un tag, une fois créé, ne se renomme ni ne se supprime : une faute de frappe ou un doublon (« IA » et « intelligence artificielle ») reste pour toujours.

## What Changes

- « Renommer… » dans le menu contextuel d'un abonnement : le nouveau titre remplace celui du flux partout (barre latérale, liste, articles déjà reçus) et survit aux rafraîchissements.
- « Renommer… » et « Supprimer le tag… » dans le menu contextuel d'un tag de la barre latérale. Le renommage vaut pour tous les cairns ; un nom déjà porté par un autre tag fusionne les deux. La suppression retire le tag de tous les articles, après confirmation.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `feed-subscriptions` : renommer un abonnement.
- `cairn` : renommer, fusionner et supprimer un tag.

## Impact

- `CairnCore` : `Library.rename(_:to:)` pour `Feed` et `Tag`, `Library.delete(_ tag:)`, erreurs de nom vide ; tests.
- `App/SidebarView.swift` : entrées de menu, alerte de nom, confirmation de suppression, sélection mise à jour.
