# Tasks

## 1. Actions d'une sélection dans le volet de lecture

- [x] 1.1 Donner à `ArticleSelectionView` une barre d'outils active (garder, marquer lu/non lu, ouvrir dans le navigateur ; article complet, résumer, partager grisés) avec ses confirmations, et vérifier en ⌘-cliquant trois articles que ces boutons sont actifs et agissent sur les trois
- [x] 1.2 Supprimer `SelectionActions` et la barre sous la liste, et vérifier que rien ne recouvre la dernière ligne en sélection multiple
- [x] 1.3 Avec deux articles sans abonnement sélectionnés, vérifier que la touche Supprimer et le menu contextuel proposent la suppression après confirmation

## 2. Intégration

- [x] 2.1 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`

## Workflow follow-up

- Commiter l'implémentation, puis archiver le change et synchroniser les specs.
