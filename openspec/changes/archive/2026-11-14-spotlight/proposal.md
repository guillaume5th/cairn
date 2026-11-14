# Proposal

## Why

Un article gardé ne se retrouve qu'en ouvrant Cairn et en cherchant dans son cairn. Spotlight est l'endroit où l'on cherche sur Mac : y trouver ses articles gardés, par titre, note ou tag, rend le cairn utile au-delà de l'app.

## What Changes

- Les articles gardés sont indexés dans Spotlight : titre, source, note, tags et nom du cairn, avec l'icône de la source.
- L'index suit les changements (garder, retirer, note, tags, cairn, restauration, purge), peu après l'enregistrement.
- Choisir un résultat ouvre Cairn sur l'article, dans son cairn.
- Les articles non gardés ne sont pas indexés. Pas de réglage : l'index est local au Mac.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `cairn` : articles gardés dans Spotlight.

## Impact

- Nouveau `App/Spotlight.swift` (Core Spotlight), `App/AppState.swift` (mise à jour après enregistrement), `App/ContentView.swift` (ouverture d'un résultat).
