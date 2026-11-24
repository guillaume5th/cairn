# Tasks

## 1. Modèle et sauvegarde (CairnCore)

- [x] 1.1 Ajouter `CairnColor` et `Cairn.color` (optionnel, nil par défaut) avec `Cairn.cairnColor` ; vérifier avec un test qu'une valeur inconnue vaut nil (`swift test --only-use-versions-from-resolved-file`)
- [x] 1.2 Ajouter `cairnColors` optionnel à `Backup`, l'écrire et le restaurer ; vérifier avec des tests : un cairn bleu revient bleu, une sauvegarde sans le champ se restaure avec des cairns sans couleur

## 2. Interface

- [x] 2.1 Teinter le symbole du cairn dans `SidebarView` et ajouter le sous-menu « Couleur » au menu contextuel d'un cairn, avec les libellés dans `Localizable.xcstrings` (fr et en) ; vérifier que le build passe
- [x] 2.2 Passer la couleur du cairn de l'article à `KeptMark` dans `ContentView`, blanc sur une ligne sélectionnée ; vérifier que le build passe

## 3. Vérification

- [ ] 3.1 Vérifier dans Cairn Dev avec `cairn-run` : colorer un cairn en bleu change son symbole et la marque de ses articles, deux cairns de couleurs différentes dans « Tous les articles », « Aucune » rend la couleur d'accent, marque blanche sur la ligne sélectionnée, article déplacé d'un cairn à l'autre change de couleur

## Workflow follow-up

- `/opsx:archive`, commit `feat:`, puis cocher l'idée dans l'issue #20 avec `/cairn-idea`.
