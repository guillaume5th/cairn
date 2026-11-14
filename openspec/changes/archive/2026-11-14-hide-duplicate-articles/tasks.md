# Tasks

## 1. Cœur

- [x] 1.1 `Library.linkKey(_:)` et ses tests (schéma, `www.`, casse de l'hôte, `/` final, fragment, `utm_*`, lien vide)
- [x] 1.2 `ingest` reçoit les liens connus et crée lu un doublon ; `refreshAll` calcule le `Set` une fois ; tests : doublon d'un autre abonnement, doublons dans le même rafraîchissement, articles sans lien
- [x] 1.3 `Library.withoutDuplicates(_:)` (gardé, sinon non lu, sinon le premier) et ses tests
- [x] 1.4 `digestArticles` sans doublons ; test dans `DigestTests`

## 2. App

- [x] 2.1 `ContentView.visibleArticles` : filtre des doublons pour « Tous les articles », « Aujourd'hui », dossier et multi-abonnements ; vérifier dans Cairn Dev avec deux abonnements partageant un article

## 3. Intégration

- [x] 3.1 `swift test` vert et `BUILD SUCCEEDED`
