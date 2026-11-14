# Tasks

## 1. Citation

- [x] 1.1 `Library.appendQuote(_:to:)` dans CairnCore : rognage, `> ` par ligne, ligne vide avant une note non vide, passage vide sans effet ; tests dans `CairnCoreTests` (`swift test` vert)

## 2. Lecteur

- [x] 2.1 `HTMLView` : lecture de la sélection par script dans `.defaultClient`, publiée en `FocusedValue` ; vérifier qu'un `print` de la sélection est juste dans Cairn Dev
- [x] 2.2 `ArticleDetailView` : action « Surligner » sur l'article affiché — garde d'abord (un cairn : direct ; plusieurs : « Surligner dans » + cairns ; ⇧⌘H sans effet si non gardé), puis `appendQuote` sur la note ; la note de l'inspecteur se met à jour
- [x] 2.3 Menu contextuel du texte : « Surligner » / « Surligner dans » ; si l'API `WebView` ne le permet pas, le noter dans design.md et s'en tenir au menu Édition

## 3. Menu et raccourci

- [x] 3.1 « Surligner » dans le menu Édition (`CairnApp.swift`, après « Rechercher »), ⇧⌘H ; sans sélection, aucune modification de la note

## 4. Vérification

- [x] 4.1 Dans Cairn Dev : scénarios de la spec (article gardé, deux paragraphes, non gardé avec un et deux cairns, aucune sélection, pas de surbrillance à la réouverture) ; `swift test` vert et `BUILD SUCCEEDED`
