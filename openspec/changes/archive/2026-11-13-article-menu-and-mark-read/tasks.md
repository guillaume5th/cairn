# Tasks

## 1. Barre latérale

- [x] 1.1 Ajouter « Marquer tout comme lu » aux menus d'un abonnement et d'un dossier, et vérifier dans l'app que les compteurs tombent à zéro et que l'action est grisée sans non lus

## 2. Articles

- [x] 2.1 Ajouter « Copier le lien » / « Copier les liens » à `ArticleMenuItems` et vérifier le contenu du presse-papiers
- [x] 2.2 Ajouter le menu « Article » (`ArticleCommands`, `ArticleSelection`) avec ⇧⌘L, ⇧⌘U et ⌘↩, et vérifier qu'il est actif avec un article affiché, grisé sans sélection, et que ⇧⌘U bascule l'article affiché

## 3. Intégration

- [x] 3.1 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`

## Workflow follow-up

- Commiter, archiver le change en synchronisant les specs, puis fusionner dans `main`.
