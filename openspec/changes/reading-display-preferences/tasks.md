# Tasks

## 1. Taille du texte

- [x] 1.1 Ajouter dans `App/CairnApp.swift`, menu Présentation, « Agrandir le texte » (⌘+), « Réduire le texte » (⌘−) et « Taille normale » (⌘0) sur `@AppStorage("articleTextScale")` : paliers de 10 % entre 0,8 et 2,0 arrondis au centième, commandes désactivées aux bornes ; vérifier que le build `xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build` réussit
- [x] 1.2 Appliquer l'échelle dans `App/HTMLView.swift` (`font-size` de base `15 × échelle` px, échelle dans l'identifiant de rechargement) et dans l'en-tête d'`App/ArticleDetailView.swift` (titre 17 pt × échelle en gras, ligne source 13 pt × échelle) ; vérifier dans l'app par captures : ⌘+ agrandit titre, ligne source, icône d'en-tête et contenu ensemble, ⌘0 revient à l'aspect actuel, « Agrandir » est désactivé à 2,0, et la taille est conservée en changeant d'article et après relancement

## 2. Icônes de la liste

- [x] 2.1 Ajouter dans le menu Présentation la case « Icônes dans la liste d'articles » sur `@AppStorage("showListIcons")` (défaut vrai) et n'afficher `SourceIcon` dans les lignes d'`ArticleListView` que si elle est cochée ; vérifier dans l'app par captures : décochée, les lignes n'ont plus d'icône mais gardent la pastille des non lus, la barre latérale et l'en-tête gardent leurs icônes, et le choix est conservé après relancement
