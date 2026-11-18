# Proposal

## Why

Parcourir la liste au clavier ne se fait aujourd'hui qu'avec Espace et N, qui sautent au prochain non lu. On ne peut ni revenir à l'article précédent, ni avancer d'un article lu à l'autre, ni garder un article sans quitter le clavier pour le menu ⇧⌘L. `j`, `k` et `s` sont les raccourcis des lecteurs de flux (Google Reader, Feedbin, NetNewsWire), à une seule touche.

## What Changes

- `k` ouvre l'article suivant de la liste (plus bas), `j` le précédent (plus haut), comme un clic : l'article s'affiche, marqué comme lu, et la liste défile jusqu'à lui. Au bout de la liste, le son d'alerte retentit et rien ne change.
- `s` garde l'article affiché, ou le retire s'il est déjà gardé (avec la confirmation habituelle s'il a une note ou des tags). Avec plusieurs cairns, il le garde dans le dernier cairn utilisé, celui de l'article gardé le plus récemment.
- Comme Espace et N, ces touches agissent quand la liste a le focus, et pas en mode sélection.

## Capabilities

### New Capabilities

### Modified Capabilities
- `article-reading`: ajout des exigences « Article suivant et précédent au clavier » et « Garder au clavier ». Les exigences existantes ne changent pas.

## Impact

- `CairnCore` : deux fonctions pures (article voisin dans une liste, dernier cairn utilisé), avec leurs tests.
- `App/ContentView.swift` : `ArticleListView` gère `j`, `k` et `s` à côté d'Espace et N.
- Aucune dépendance, aucun changement du modèle de données : le dernier cairn se déduit de `keptAt`.
- Hors périmètre : raccourcis dans l'article lui-même, raccourcis personnalisables, touches pour Lire plus tard ou Marquer.
