# Tasks

## 1. Barre de progression

- [x] 1.1 `HTMLView` : lire la fraction défilée avec `webViewOnScrollGeometryChange` (contentOffset / (contentSize − hauteur visible)), nil quand le contenu tient dans le volet ; ne pas passer par un script, le JS du flux reste désactivé ; vérifier dans Cairn Dev qu'une valeur suit le défilement
- [x] 1.2 Afficher un trait de 2 points couleur d'accent, sans piste, sur le séparateur sous l'en-tête (au-dessus du résumé), la progression remontant d'`HTMLView` à `ArticleDetailView` par un binding, masqué pour nil, sans intercepter les clics ni être lue par VoiceOver à chaque défilement ; vérifier dans Cairn Dev : vide en haut, moitié, pleine en bas, absente sur un article court, vide à la réouverture

## 2. Vérification

- [x] 2.1 Scénarios de la spec dans Cairn Dev, en clair et en sombre, et avec la recherche (le défilement vers le terme fait avancer la barre) ; `swift test` vert et `BUILD SUCCEEDED`
