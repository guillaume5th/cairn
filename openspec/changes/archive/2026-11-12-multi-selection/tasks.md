# Tasks

## 1. Règle de sélection dans CairnCore

- [x] 1.1 Ajouter `SelectionRule.restrict(old:new:groupable:)` (garde l'ensemble s'il n'a qu'un élément ou que des éléments groupables, sinon seulement l'élément ajouté) ; vérifier par des tests : ajout d'un abonnement à un abonnement → deux, ajout d'un dossier à deux abonnements → le dossier seul, ⇧-clic qui ajoute plusieurs éléments dont un non groupable → cet élément seul

## 2. Abonnements dans la barre latérale

- [x] 2.1 Passer `SidebarView` à `Binding<Set<SidebarItem>>` et `ContentView` à `memory.item` + `multiFeeds` normalisés par `SelectionRule` ; lister ensemble les articles des abonnements sélectionnés (titre « N abonnements », pas de mémoire d'article) ; vérifier dans l'app que ⌘-clic sur deux abonnements liste leurs articles, qu'un dossier ajouté remplace la sélection, et qu'après relance la dernière entrée simple est affichée
- [x] 2.2 Remplacer les `.contextMenu` des lignes de la barre latérale par un `contextMenu(forSelectionType: SidebarItem.self)` (cairn, dossier, abonnements) avec « Déplacer vers » et « Supprimer N abonnements… » sur le lot (une confirmation, retour à « Tous les articles ») ; vérifier dans l'app que le menu d'un cairn et d'un dossier est inchangé et que trois abonnements se déplacent et se suppriment d'un coup
- [x] 2.3 Faire glisser la sélection d'abonnements (`dragContainer` + `dragContainerSelection` + `draggable(containerItemID:)`) ; vérifier dans l'app que deux abonnements glissés sur un dossier y sont rangés, et qu'un abonnement non sélectionné glissé part seul

## 3. Articles

- [x] 3.1 Passer `ArticleListView` à une sélection `Set` (binding décrit dans le design : `multiArticles` non persistant, mémoire et `pickedID` seulement pour un article seul) ; vérifier dans l'app que ⌘A sélectionne tout sans rien marquer lu, qu'un clic simple affiche et marque lu un article, et que revenir sur l'entrée restaure l'article mémorisé d'avant
- [x] 3.2 Généraliser `KeepButton` et `unkeepConfirmation` à `[Article]` (garder ou déplacer le lot, « Retirer du cairn » si tous gardés, confirmation unique avec le nombre d'articles ayant note ou tags) ; vérifier dans l'app sur une sélection mixte avec deux cairns, puis avec un seul cairn
- [x] 3.3 Remplacer le `.contextMenu` des lignes par `contextMenu(forSelectionType: PersistentIdentifier.self)` : garder, lu/non lu selon le lot, ouvrir dans le navigateur (confirmation au-delà de 10), « Supprimer N articles… » si tous orphelins ; étendre `onDeleteCommand` au lot ; vérifier dans l'app le menu sur une ligne sélectionnée (lot) et sur une ligne hors sélection (elle seule)
- [x] 3.4 Ajouter `SelectionSummary` (« N articles sélectionnés ») dans le volet de lecture avec la barre d'outils du lot ; vérifier dans l'app l'affichage pour trois articles, la position stable des boutons de la liste, et le retour à l'article au clic simple

## 4. Résumés

- [x] 4.1 Passer `DigestListView` à une sélection `Set`, `DigestDeleteConfirmation` à `[Digest]` (« Supprimer N résumés ? »), et afficher `SelectionSummary` (« N résumés sélectionnés ») avec la corbeille dans le volet ; vérifier dans l'app la suppression de deux résumés de test par la touche Supprimer et par la corbeille, puis l'affichage du résumé restant

## 5. Intégration

- [x] 5.1 Lancer `swift test` et compiler l'app ; vérifier que tout passe
- [x] 5.2 Parcourir les scénarios des quatre deltas de `specs/` dans l'app (via l'accessibilité) et lister à l'utilisateur ceux qui demandent un vrai ⌘-clic à vérifier à la main

## Workflow follow-up

- Archiver le change une fois validé (`/opsx:archive`).
