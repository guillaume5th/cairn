# Design

## Context

`ArticleListView` gère déjà Espace et N avec `list.onKeyPress(keys:)` quand la liste a le focus, en sélectionnant l'article comme un clic (la sélection mémorisée le marque lu) et en défilant avec `ScrollViewProxy`. `Library.nextUnread(after:in:)` porte la logique, testée dans CairnCore. « Garder » passe par `Library.keep(_:in:)` et `KeepButton.unkeep(_:confirming:)`, dont la confirmation (`unkeepConfirmation`) est déjà branchée sur la liste. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Réutiliser le chemin d'Espace et N, et celui du bouton Garder, sans nouvelle donnée.

**Non-Goals:**
- Touches actives quand le focus est dans l'article (la vue web garde ses propres touches, comme pour Espace).

## Decisions

- **Logique pure dans CairnCore** : `Library.neighbor(of:in:offset:)` renvoie l'article à `offset` (+1 ou −1) de l'article courant dans la liste, le premier quand il n'y a pas d'article courant (quelle que soit la direction), nil au bout. `Library.lastUsedCairn(context:)` renvoie le cairn de l'article de plus grand `keptAt`, sinon le premier cairn par nom. Testables sans interface, comme `nextUnread`.
- **`k` descend, `j` remonte** : choix de l'utilisateur, inverse de la convention vim ; `k` appelle `neighbor` avec +1, `j` avec −1.
- **Une seule gestion des touches** : `onKeyPress(keys: [.space, "n", "j", "k", "s"])` avec un `switch` sur la touche. `j`/`k` sélectionnent et font défiler comme `openNextUnread`, et sonnent au bout de la liste.
- **Le dernier cairn se déduit, sans réglage stocké** : `keptAt` est déjà posé à chaque fois qu'on garde ; l'article gardé le plus récemment désigne le cairn. Alternative écartée : mémoriser le dernier cairn dans `@AppStorage`, qui duplique une information déjà là et se périme quand un cairn est supprimé.
- **`s` agit sur l'article affiché seul** : avec plusieurs articles sélectionnés, la touche est ignorée (le menu Article et ⇧⌘L restent là pour une sélection). Retirer passe par `KeepButton.unkeep`, donc la même confirmation.
- **Touches sans modificateur, seulement quand la liste a le focus** : aucun conflit avec le champ de recherche ni la note, qui ont le focus quand on y tape.

## Risks / Trade-offs

- [Le dernier cairn utilisé surprend si l'article le plus récemment gardé a été déplacé à la main dans un autre cairn] → `keep(_:in:)` ne change pas `keptAt` lors d'un déplacement, donc le cairn retenu reste celui où l'on a gardé en dernier ; comportement documenté dans la spec par « l'article gardé le plus récemment ».
- [Clavier non QWERTY/AZERTY] → `j`, `k`, `s` sont aux mêmes caractères ; `onKeyPress` compare le caractère produit, pas la position.
