# Proposal

## Why

Pour voir ce qui vient de sortir, il faut parcourir « Tous les articles » et repérer les dates. Une vue « Aujourd'hui » donne d'un coup les articles du jour, tous abonnements confondus.

## What Changes

- Entrée « Aujourd'hui » dans la barre latérale, sous « Tous les articles » : les articles publiés depuis minuit (heure locale), avec le nombre de non lus du jour.
- Elle se comporte comme « Tous les articles » : recherche, filtre « Non lus », ordre, prochain non lu, sélection mémorisée.
- Pas de vue « Non lus » globale : « Tous les articles » avec le filtre « Non lus seulement » le fait déjà.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : vue « Aujourd'hui ».

## Impact

- `App/ContentView.swift` (`SidebarItem.today`, titre, liste), `App/SidebarView.swift` (entrée et compteur).
