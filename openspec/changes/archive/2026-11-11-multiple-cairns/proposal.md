# Proposal

## Why

Le cairn est unique : la veille professionnelle et les lectures personnelles s'y mélangent, et les tags ne suffisent pas à séparer des collections qu'on veut consulter isolément. Plusieurs cairns nommés permettent de tenir des collections distinctes, chacune avec ses articles et ses tags.

## What Changes

- L'utilisateur peut créer plusieurs cairns nommés (« Pro », « Perso »…), les renommer et les supprimer. Le cairn actuel devient un cairn nommé « Cairn » qui garde tous les articles déjà gardés.
- Un article gardé est dans un seul cairn. Le bouton « Garder » ouvre un menu des cairns (avec un seul cairn, le clic garde directement, comme aujourd'hui) ; le clic droit propose « Garder dans ».
- Un article gardé peut passer d'un cairn à un autre sans perdre sa note ni ses tags (même menu, cairn actuel coché).
- Dans la barre latérale, une section « Cairns » liste chaque cairn, avec sous lui les tags de ses propres articles ; le « + » de la section crée un cairn. Chaque cairn et chaque tag d'un cairn a sa vue, avec recherche, filtre et sélection mémorisée.
- Supprimer un cairn retire ses articles du cairn (note et tags perdus), après une confirmation indiquant leur nombre. Le dernier cairn ne peut pas être supprimé.
- Les tags restent partagés : un même tag peut servir dans plusieurs cairns et les suggestions viennent de tous les cairns.

## Capabilities

### New Capabilities
<!-- Aucune. -->

### Modified Capabilities
- `cairn` : plusieurs cairns (création, renommage, suppression), choix du cairn en gardant un article, déplacement entre cairns, vue et tags par cairn.

## Impact

- **Données** : nouveau modèle `Cairn` (SwiftData, compatible CloudKit) et relation optionnelle `Article.cairn`. Au lancement, s'il n'existe aucun cairn, un cairn « Cairn » est créé ; tout article gardé sans cairn y est rangé (articles existants, ou venus d'un appareil pas encore à jour).
- **Code** : `CairnCore` (`Models`, `Library` : garder dans un cairn, déplacer, opérations sur les cairns, rattrapage au lancement, tests) ; `App/SidebarView.swift` (section Cairns) ; `App/ContentView.swift` (`SidebarItem` par cairn et par tag d'un cairn, liste, titre, mémoire) ; `App/ArticleDetailView.swift` (`KeepButton` en menu) ; `App/AppState.swift` (rattrapage au lancement).
- **Dépendances** : aucune nouvelle.
