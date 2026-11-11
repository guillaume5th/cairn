# Tasks

## 1. Extrait de recherche

- [x] 1.1 Ajouter `Library.snippet(for:in:)` dans `CairnCore/Sources/CairnCore/Library.swift` (nil si le titre contient le terme ou si le terme est vide ; sinon première occurrence dans la note, puis les tags, puis le contenu réduit en texte ; ~40 caractères avant, ~80 après, coupés sur une espace, « … » aux coupures ; correspondance insensible à la casse et aux accents) ; ajouter des tests dans `LibraryTests` (terme dans le titre → nil, dans la note, dans un tag, dans un contenu HTML avec balise et entité, sans accent, coupure avec « … ») et vérifier que `swift test` passe

## 2. Surlignage dans la liste et le titre

- [x] 2.1 Ajouter dans l'app une fonction qui construit un `AttributedString` surligné (fond `Color.yellow.opacity(0.45)` sur chaque occurrence, même correspondance) ; l'utiliser pour le titre des lignes d'`ArticleListView`, afficher sous le titre l'extrait surligné quand `Library.snippet` en renvoie un, et pour le titre d'`ArticleDetailView` ; transmettre `searchText` de `ContentView` à la liste et à l'article ; vérifier que le build réussit

## 3. Surlignage du contenu

- [x] 3.1 Dans `App/HTMLView.swift`, recevoir le terme, ajouter le style `mark` au CSS de la page et appeler après chaque chargement et à chaque changement du terme un script via `callJavaScript` (arguments, sans réactiver les scripts du contenu) qui retire les anciens `<mark>`, surligne toutes les occurrences repliées (casse, accents) dans les nœuds texte et fait défiler la première au centre ; vérifier que le build réussit

## 4. Vérification

- [x] 4.1 Vérifier dans l'app par captures : un mot du titre est surligné sans extrait ; un mot présent seulement dans le contenu donne un extrait surligné ; « deploiement » surligne « Déploiement » ; l'article affiché a toutes ses occurrences surlignées et défile jusqu'à la première ; effacer la recherche retire surlignages et extraits ; une ligne sélectionnée reste lisible
