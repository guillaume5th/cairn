# Proposal

## Why

En sélection multiple, la barre du volet de lecture affiche Garder, Marquer et Ouvrir dans le navigateur, mais grisés. Les mêmes actions, actives, sont dans une barre flottante sous la liste, qui recouvre la dernière ligne visible. L'utilisateur voit en haut des boutons qui semblent refuser la sélection, alors que la vraie commande est en bas.

## What Changes

- En sélection multiple et en mode sélection, les actions sur la sélection passent dans la barre d'outils du volet de lecture, aux mêmes places que pour un seul article. Garder, Marquer comme lu ou non lu et Ouvrir dans le navigateur sont actifs ; Article complet, Résumer et Partager restent grisés.
- **BREAKING** (comportement) : la barre d'actions sous la liste disparaît. La suppression des articles sans abonnement reste disponible par le menu contextuel et la touche Supprimer.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : les actions d'une sélection sont dans la barre du volet de lecture au lieu de sous la liste, et les boutons du volet sans article sont actifs pour une sélection.

## Impact

- `App/ArticleDetailView.swift` : barre d'outils active du volet de sélection multiple, avec ses confirmations.
- `App/ContentView.swift` : suppression de la barre d'actions sous la liste.
- Aucun impact sur `CairnCore`, les données ni les raccourcis.
