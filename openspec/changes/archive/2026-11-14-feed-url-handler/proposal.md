# Proposal

## Why

Les sites et les navigateurs proposent des liens `feed:` (« S'abonner »). Aujourd'hui ils n'ouvrent rien dans Cairn : il faut copier l'adresse et la coller dans « Ajouter un abonnement ».

## What Changes

- Cairn se déclare comme application du schéma `feed:`.
- Ouvrir un lien `feed:https://…` ou `feed://…` amène Cairn au premier plan avec « Ajouter un abonnement » pré-rempli de l'adresse ; l'utilisateur confirme, et la découverte de flux habituelle s'applique.
- Pas d'extension Safari.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `feed-subscriptions` : s'abonner depuis un lien `feed:`.

## Impact

- `project.yml` (`CFBundleURLTypes`), `CairnCore` (`Library.address(fromFeedLink:)`, testé), `App/ContentView.swift` (`onOpenURL`).
