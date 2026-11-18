# Tasks

## 1. Logique dans CairnCore

- [x] 1.1 Ajouter `SearchToken` (source, tag, non lu, gardé) et `Library.filter(_:tokens:)` (OU dans un type, ET entre types) ; vérifier avec des tests : une source, deux sources, tag insensible à la casse et aux accents sur deux cairns, « Gardés », combinaison tag + non lu, aucun jeton (`swift test --only-use-versions-from-resolved-file`)
- [x] 1.2 Ajouter `Library.suggestedTokens(for:in:)` ; vérifier avec des tests : texte vide sans proposition, « kor » propose la source, préfixes `source:` et `tag:`, jetons fixes, jetons déjà présents exclus, limite de 10

## 2. Champ de recherche

- [x] 2.1 Dans `ContentView`, passer la liste d'articles à `.searchable(text:tokens:suggestedTokens:…)` avec le libellé de chaque jeton, appliquer `Library.filter` dans `visibleArticles`, et vider les jetons quand l'entrée ou la sélection d'abonnements change ; vérifier que le build passe
- [x] 2.2 Vérifier dans Cairn Dev avec `cairn-run` : « kor » propose Korben et le choisir crée le jeton, deux sources élargissent, « Non lus » + texte restreint, changer d'entrée vide le champ, la vue « Résumés quotidiens » ne propose aucun jeton
