# Proposal

## Why

Cairn sélectionne automatiquement le premier article d'une entrée de la barre latérale quand aucun article n'y est mémorisé. Ce choix évitait surtout que la barre d'outils change de disposition quand le volet de lecture est vide. Depuis que ce volet garde ses boutons grisés (exigence « Barre d'outils du volet sans article »), il n'a plus de raison d'être, et il affiche un article que l'utilisateur n'a pas choisi.

## What Changes

- Une entrée sans article mémorisé (premier lancement, entrée jamais ouverte, vue d'un dossier) n'affiche plus aucun article : le volet indique « Aucun article sélectionné », avec ses boutons grisés.
- Quand l'article mémorisé n'est plus dans la liste (filtre « Non lus », recherche, purge, suppression, désabonnement), aucun article n'est sélectionné, au lieu du premier.
- Inchangé : chaque entrée retient l'article que l'utilisateur a choisi, et le retrouve à son retour et au relancement ; un article affiché sans clic de l'utilisateur reste non lu.
- Inchangé : « Résumés quotidiens » affiche toujours le résumé le plus récent quand aucun n'est mémorisé.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading`: plus de sélection d'article par défaut ; un article mémorisé absent de la liste ne laisse place à aucun article ; les exigences « Vue d'un dossier » et « État lu / non lu » ne parlent plus de sélection par défaut.

## Impact

- `App/ContentView.swift` : l'article affiché d'une entrée et la remise à zéro de la mémoire à l'ouverture d'une entrée.
- Aucun impact sur `CairnCore`, les données ni les résumés quotidiens.
