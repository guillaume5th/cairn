# Proposal

## Why

Trier la liste demande aujourd'hui un clic droit ou un raccourci par article. Un balayage du trackpad sur la ligne, comme dans Mail, suffit pour les gestes les plus fréquents : marquer lu et mettre de côté.

## What Changes

- Balayage vers la droite sur une ligne d'article : « Marquer comme lu » ou « Marquer comme non lu ».
- Balayage vers la gauche : « Lire plus tard » (ou « Retirer de Lire plus tard ») et, quand c'est possible sans choisir de cairn, « Garder » ou « Retirer du cairn ».
- « Garder » n'est proposé que s'il n'existe qu'un cairn ; « Retirer du cairn » l'est pour un article gardé, quel que soit le nombre de cairns, avec la même confirmation qu'ailleurs quand il a des notes ou des tags. Avec plusieurs cairns, garder reste dans le menu contextuel et la barre d'outils.
- Le balayage agit sur la ligne balayée seule, sans changer la sélection ni marquer l'article lu.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : actions par balayage sur les lignes de la liste d'articles.

## Impact

- `App/ContentView.swift` : `.swipeActions` sur les lignes de la liste.
- Réutilise `ReadLaterButton`, `KeepButton` (ou sa logique) et `unkeepConfirmation` d'`App/ArticleDetailView.swift`.
