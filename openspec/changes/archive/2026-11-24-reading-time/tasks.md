# Tasks

## 1. Calcul dans CairnCore

- [x] 1.1 Ajouter `Library.readingMinutes(_:)` (230 mots par minute, minimum 1, `nil` sans texte, un seul passage sur les octets) ; vérifier avec un test : texte vide, texte court, 2 300 mots donnent 10 minutes (`swift test`)

## 2. Affichage

- [x] 2.1 Afficher « · N min read » dans l'en-tête de `ArticleDetailView` et ajouter « %lld min read » (fr : « %lld min de lecture ») à `Localizable.xcstrings` ; vérifier que le build passe
- [x] 2.2 Afficher l'icône `timer` et « N min » après la source dans la ligne de `ContentView`, la date relative restant seule à droite ; vérifier dans Cairn Dev avec `cairn-run` : durée cohérente entre la liste et l'en-tête, rien pour un article sans texte, liste fluide
