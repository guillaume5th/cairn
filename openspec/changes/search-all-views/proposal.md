# Proposal

## Why

La recherche n'existe que dans la vue Cairn et ses tags. Pour retrouver un article reçu mais pas gardé, il faut parcourir « Tous les articles » ou un abonnement à l'œil.

## What Changes

- Toutes les vues de la barre latérale ont un champ de recherche : « Tous les articles », chaque abonnement, Cairn et chaque tag. Il filtre la liste de la vue courante.
- La recherche porte sur le titre, le contenu, la note et les tags. Elle ne tient compte ni de la casse ni des accents, comme la recherche actuelle du cairn.
- La recherche se combine avec le filtre « Non lus ».
- Le texte recherché est effacé quand on change d'entrée dans la barre latérale, comme aujourd'hui.
- **BREAKING (comportement)** : ⌘F place le curseur dans le champ de recherche de la vue courante au lieu de basculer sur la vue Cairn. La commande de menu « Rechercher dans le cairn » devient « Rechercher ». Pour chercher dans le cairn, on ouvre Cairn puis ⌘F.

## Capabilities

### New Capabilities
<!-- Aucune. -->

### Modified Capabilities
- `article-reading` : ajout d'une exigence de recherche dans la liste courante, toutes vues confondues, avec le raccourci ⌘F.
- `cairn` : retrait de l'exigence « Recherche dans le cairn », couverte désormais par la recherche de `article-reading` (la vue Cairn est une liste comme les autres).

## Impact

- **Code** : `App/ContentView.swift` (champ de recherche sur toutes les listes, focus ⌘F) ; `App/CairnApp.swift` (libellé de la commande ⌘F). `Library.search` est réutilisé tel quel.
- **Performance** : la recherche parcourt désormais tous les articles reçus, pas seulement les gardés. La purge à 30 jours en limite le nombre ; le parcours linéaire existant reste suffisant.
- **Dépendances** : aucune nouvelle.
