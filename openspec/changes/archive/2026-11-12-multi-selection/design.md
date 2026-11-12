# Design

## Context

Voir proposal.md (Why) et les deltas de `specs/`. État actuel, observé dans le code :

- `ContentView` tient une sélection d'article unique : `memory.articles[entry]` (mémorisée par entrée et entre lancements, `SelectionMemory`) et `pickedID` (seul l'article choisi par l'utilisateur est marqué lu). `ArticleListView` lie `List(selection:)` à un `PersistentIdentifier?`.
- Les actions sur un article sont dans un `.contextMenu` par ligne (`ArticleListView`), dans la barre d'outils d'`ArticleDetailView` (`KeepButton`, « Marquer comme non lu », « Ouvrir dans le navigateur ») et dans `onDeleteCommand` (orphelins).
- `SidebarView` lie `List(selection:)` à un `SidebarItem?` ; chaque ligne d'abonnement, de dossier et de cairn a son propre `.contextMenu` ; un abonnement se fait glisser par `.draggable(feed.url)` vers un dossier (`dropDestination(for: String.self)`).
- `DigestListView` : `selection: PersistentIdentifier?`, `.contextMenu` par ligne, `onDeleteCommand`, `DigestDeleteConfirmation` ; le volet `DigestDetail` porte la corbeille.
- `Library` offre déjà les opérations unitaires (`keep(_:in:)` qui déplace un article déjà gardé en gardant note et tags, `unkeep`, `delete(_ article:)` limité aux orphelins, `move(_:to:)`, `delete(_ feed:)`).

## Goals / Non-Goals

**Goals:**
- Uniquement des API SwiftUI standard pour la sélection, les menus et le glisser-déposer.
- Un seul chemin de code par action : l'action unitaire devient le cas « lot d'un élément ».

**Non-Goals:**
- Sélection multiple de dossiers, cairns ou tags dans la barre latérale.
- Annuler (⌘Z) une action de lot.
- Mémoriser une sélection multiple.

## Decisions

**Sélections en `Set`, mémoire inchangée.** Les trois listes passent à `List(selection: Binding<Set<…>>)`, ce qui donne gratuitement ⌘-clic, ⇧-clic, ⇧-flèche et « Tout sélectionner » (⌘A). Pour les articles, le binding se calcule ainsi : un ensemble `@State multiArticles` non persistant quand il contient plusieurs éléments, sinon `{displayedArticleID}`. Le setter écrit `memory.articles[entry]` et `pickedID` seulement quand l'ensemble a un seul élément (marquage lu inchangé), sinon il remplit `multiArticles`. `multiArticles` est vidé au changement d'entrée : la mémoire reste celle d'avant la sélection multiple. `SelectionMemory` ne change pas de format, donc aucune migration. Même principe pour les résumés (`memory.articles[.digests]`).
Alternative écartée : persister des ensembles dans `SelectionMemory`. La spec ne le demande pas, et il faudrait migrer le format JSON.

**Barre latérale : abonnements seulement.** `SidebarView` reçoit un `Binding<Set<SidebarItem>>`. `ContentView` garde `memory.item` (entrée simple, persistée) plus un `@State multiFeeds: Set<PersistentIdentifier>` non persistant. Le setter normalise : si le nouvel ensemble a plus d'un élément et contient autre chose qu'un abonnement, on ne garde que l'élément ajouté (différence avec l'ancien ensemble). Cette règle pure va dans `CairnCore` (`SelectionRule.restrict(old:new:groupable:)`, générique), testée sans UI. Avec plusieurs abonnements, `visibleArticles` filtre sur `multiFeeds`, le titre devient « N abonnements », et il n'y a pas de mémoire d'article pour cette vue.

**Menus contextuels : `contextMenu(forSelectionType:)`.** Les `.contextMenu` par ligne des trois listes sont remplacés par la variante de sélection sur la `List`. Elle reçoit la sélection si la ligne cliquée en fait partie, sinon la seule ligne cliquée : c'est le comportement demandé par la spec, sans code de notre côté. Dans la barre latérale, le même menu traite selon le contenu de l'ensemble un cairn (Renommer, Supprimer), un dossier (Renommer, Supprimer) ou des abonnements (Déplacer vers, Supprimer N abonnements).
Risque vérifié à l'implémentation : un `.contextMenu` par ligne restant masquerait la variante de sélection, d'où le remplacement complet.

**Actions de lot : boucles sur les opérations existantes.** L'app appelle les fonctions unitaires de `Library` pour chaque élément. Pas de nouvelle API de lot : `keep(_:in:)` gère déjà le déplacement d'un article gardé (sélection mixte). Les règles d'étiquette sont calculées sur le lot :
- « Marquer comme lu » si au moins un article est non lu, sinon « Marquer comme non lu ».
- « Retirer du cairn » seulement si tous sont gardés ; confirmation unique si au moins un a une note ou des tags, avec le nombre concerné.
- « Supprimer N articles… » seulement si tous sont orphelins, aussi pour `onDeleteCommand`.
- « Ouvrir dans le navigateur » ouvre chaque lien, avec confirmation au-delà de 10.

`KeepButton` et `unkeepConfirmation` passent de `Article` à `[Article]`. `DigestDeleteConfirmation` passe de `Digest?` à `[Digest]` ; `feedToDelete` devient `[Feed]`.

**Volet de lecture d'une sélection multiple.** Une petite vue `SelectionSummary` (un `ContentUnavailableView` « N articles sélectionnés », ou « N résumés sélectionnés ») porte la même barre d'outils que le volet d'un article ou d'un résumé, appliquée au lot. La barre d'outils du volet existe ainsi dans tous les cas, ce qui évite que les boutons de la liste se déplacent (problème déjà rencontré dans `DigestDetail`).

**Glisser plusieurs abonnements.** `.draggable(feed.url)` devient `.draggable(containerItemID: feed.url)` avec `.dragContainer(for: String.self) { $0 }` et `.dragContainerSelection(selectedFeedURLs)` sur la liste. Les `dropDestination(for: String.self)` existants reçoivent déjà un tableau d'URL : ils ne changent pas.

## Risks / Trade-offs

- [`List(selection: Set)` dans la barre latérale avec `OutlineGroup`/`DisclosureGroup` des dossiers] → à vérifier tôt (tâche 2.1) ; repli : gérer le ⌘-clic des abonnements par la même normalisation, sans changer de contrôle.
- [Reconstruction de la liste d'articles par `.id(articles.count)` au rafraîchissement] → la sélection vit dans nos états et non dans la `List` : elle survit, mais le défilement revient en haut, comme aujourd'hui.
- [Vérification des gestes] → les clics simulés n'atteignent pas l'app dans cet environnement ; la vérification passe par l'accessibilité (⌘A, flèches avec ⇧, menus via `AXShowMenu`), et un contrôle manuel du ⌘-clic par l'utilisateur.
- [Ouvrir beaucoup d'onglets] → confirmation au-delà de 10.

## Migration Plan

Aucune migration : pas de changement de modèle ni du format de `SelectionMemory`.
