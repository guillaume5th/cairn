# Design

## Context

`ArticleDetailView` empile l'article (`HTMLView`) puis, si l'article est gardé, un `Divider` et `KeptEditor` (note en `TextEditor`, tags en `TagFlowLayout` de capsules teintées, champ d'ajout, suggestions). La barre d'outils du volet de lecture est `ReaderToolbar`, partagée par l'article, la sélection multiple et le volet vide (`ReaderToolbar.empty`) pour garder la même disposition. Les cairns se choisissent via `KeepButton` (menu quand il y en a plusieurs). Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Un inspecteur SwiftUI standard (`.inspector`), sans style fait main.
- Une barre d'outils qui garde sa disposition dans tous les états du volet.

**Non-Goals:**
- Champ à jetons AppKit (`NSTokenField`) : écarté par l'utilisateur au profit des capsules.
- Inspecteur pour une sélection multiple (notes communes) ou pour un résumé quotidien.
- Changer le modèle : la note reste un seul texte (`Article.note`), seul le libellé devient « Notes ».

## Decisions

- **`.inspector(isPresented:)` sur `ArticleDetailView`**, avec `.inspectorColumnWidth(min: 220, ideal: 260, max: 360)`. Il n'existe donc que quand un article est lu : en sélection multiple ou sans article, il n'y a pas d'inspecteur, et son bouton est grisé. Alternative écartée : l'attacher au `NavigationSplitView` entier, qui l'afficherait aussi pour les résumés quotidiens.
- **État dans `@AppStorage("inspectorShown")`, vrai par défaut** : les notes restent visibles comme aujourd'hui, et le choix de l'utilisateur est conservé.
- **Visibilité indépendante de l'état gardé** : l'inspecteur ne s'ouvre ni ne se ferme quand on passe d'un article gardé à un autre qui ne l'est pas, sinon la largeur de l'article changerait en parcourant la liste. Un article non gardé affiche `ContentUnavailableView` (« Article non gardé », « Garde-le pour lui ajouter des notes et des tags. ») avec `KeepButton`.
- **Contenu en `Form` `.formStyle(.grouped)`** :
  - Section « Informations » : `Picker` des cairns quand il y en a plusieurs (il appelle `Library.keep(_:in:)`, qui déplace avec note et tags), sinon `LabeledContent` du nom ; `LabeledContent("Gardé le")` avec `keptAt`.
  - Section « Notes » : `TextEditor` sans fond ajouté, hauteur minimale de quelques lignes, libellé d'accessibilité « Notes personnelles ».
  - Section « Tags » : `TagFlowLayout` existant, capsules en `.fill.tertiary` avec texte principal (au lieu de la teinte d'accent à 20 %), bouton de retrait `xmark.circle.fill` en secondaire ; champ « Ajouter un tag » en `.roundedBorder` ; suggestions comme aujourd'hui.
- **Bouton de la barre d'outils** : `Toggle` « Inspecteur » avec le symbole `sidebar.trailing`, en dernier dans `ReaderToolbar`, après Ouvrir dans le navigateur, séparé par un `ToolbarSpacer`. Il lit et écrit la même clé `inspectorShown`. Grisé dans `ReaderToolbar` quand `articles.count != 1` et dans `ReaderToolbar.empty`.
- **Menu Présentation : commande maison « Afficher / Masquer l'inspecteur » (⌃⌘I)** sur la même clé que le bouton. Constaté à l'implémentation : `InspectorCommands()` affiche « Inspecteur Show », à moitié traduit ; la commande maison garde son raccourci standard.
- **Le volet du bas est supprimé**, avec son `Divider`.

## Risks / Trade-offs

- [Inspecteur et `NavigationSplitView` à trois colonnes : la fenêtre peut manquer de largeur] → l'inspecteur se replie de lui-même quand la place manque ; vérifier à la largeur minimale de la fenêtre.
- [Pas de test automatisé de l'interface] → captures dans Cairn Dev, en clair et en sombre.
