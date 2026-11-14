# Proposal

## Why

Un même article arrive souvent par plusieurs abonnements (un agrégateur et le blog d'origine, un flux global et un flux de catégorie). Il apparaît alors deux fois dans « Tous les articles », compte deux fois dans les non lus et doit être lu deux fois.

## What Changes

- Un article dont le lien (normalisé) est déjà connu via un autre abonnement est enregistré comme **déjà lu** au rafraîchissement : lire l'original vaut lecture de ses copies, et les compteurs ne le comptent qu'une fois.
- Les listes qui mélangent plusieurs abonnements (« Tous les articles », « Aujourd'hui », un dossier, plusieurs abonnements sélectionnés) n'affichent qu'une ligne par lien. La vue d'un abonnement et les vues de cairn montrent toujours tous leurs articles.
- Le résumé quotidien ne résume et ne liste qu'une fois chaque lien.

## Capabilities

### New Capabilities

### Modified Capabilities
- `feed-fetching` : un article reçu dont le lien est déjà connu via un autre abonnement est créé lu.
- `article-reading` : une seule ligne par lien dans les listes multi-abonnements.
- `daily-digest` : un seul exemplaire de chaque lien dans le résumé.

## Impact

- `CairnCore/Library.swift` : `ingest`, normalisation du lien, filtre des doublons, `digestArticles`.
- `App/ContentView.swift` : `visibleArticles` applique le filtre aux vues multi-abonnements.
- `CairnCore/Tests/CairnCoreTests/LibraryTests.swift`, `DigestTests.swift` : nouveaux tests.
- Pas de changement de schéma SwiftData.
