# Tasks

## 1. Barre du lecteur commune

- [x] 1.1 Remplacer les barres de `ArticleDetailView`, `ArticleSelectionView` et `DisabledReaderToolbar` par `ReaderToolbar`, et vérifier dans l'app que les trois états (un article, trois articles cochés, aucun article) ont les mêmes boutons au même endroit
- [x] 1.2 Vérifier sur un article affiché que « Marquer comme non lu » le remet en non lu, puis que le bouton devenu « Marquer comme lu » le remet en lu
- [x] 1.3 En mode sélection avec un seul article coché, choisir Partager et vérifier que la feuille de partage s'ouvre avec cet article ; avec deux articles cochés, vérifier que Partager est grisé

## 2. Intégration

- [x] 2.1 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`

## Workflow follow-up

- Commiter l'implémentation avec les autres corrections du même diff, puis archiver le change et synchroniser les specs.
