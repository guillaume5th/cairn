# Tasks

## 1. Inspecteur

- [x] 1.1 Retirer le volet du bas d'`ArticleDetailView` et ajouter `.inspector` lié à `@AppStorage("inspectorShown")` (vrai par défaut), avec une largeur de colonne bornée
- [x] 1.2 Réécrire `KeptEditor` en `Form` groupé : section Cairn (choix du cairn ou nom, « Gardé le »), section « Notes », section « Tags » ; pour un article non gardé, `ContentUnavailableView` avec `KeepButton`
- [x] 1.3 Capsules de tags aux couleurs système neutres, bouton de retrait `xmark.circle.fill`, champ d'ajout en `.roundedBorder`, suggestions conservées

## 2. Commandes

- [x] 2.1 Ajouter le bouton Inspecteur en dernier dans `ReaderToolbar`, grisé sauf pour un seul article affiché, et dans `ReaderToolbar.empty`
- [x] 2.2 Ajouter au menu Présentation une commande « Afficher / Masquer l'inspecteur » (⌃⌘I) sur la même clé que le bouton (`InspectorCommands()` écarté : libellé à moitié traduit)

## 3. Vérification

- [x] 3.1 Captures dans Cairn Dev : article gardé avec notes et tags, article non gardé, inspecteur fermé, sélection multiple, en clair et en sombre ; vérifier que l'état est conservé après relance et que changer de cairn depuis l'inspecteur garde notes et tags
- [x] 3.2 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`
