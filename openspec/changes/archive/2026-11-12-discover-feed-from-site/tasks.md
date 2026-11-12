# Tasks

## 1. Découverte dans CairnCore

- [x] 1.1 Extraire `HTMLHead.links(in:baseURL:)` de `FeedIcon` et faire passer `declaredIcons` par lui ; les tests FeedIconTests existants passent sans modification
- [x] 1.2 Normalisation de l'adresse (ajout de `https://`) ; tests : « exemple.com », « exemple.com/blog », URL complète inchangée, schéma non http refusé
- [x] 1.3 `Library.discoverFeeds` : flux direct, liens `alternate` (RSS, Atom, JSON Feed, URL relatives, doublons), chemins usuels, `CairnError.noFeedFound` ; tests avec `StubProtocol` et des pages HTML dans `Fixtures/`

## 2. Ajout depuis l'app

- [x] 2.1 `AppState.addFeed` : découverte puis ajout direct d'un flux unique ; message « Aucun flux trouvé sur ce site » ; vérifier sur Mac avec un blog qui déclare son flux
- [x] 2.2 Choix entre plusieurs flux (`confirmationDialog`, flux déjà suivis désactivés, annulation sans effet) sur Mac et sur le simulateur iPhone
- [x] 2.3 Mettre à jour le texte d'aide du champ (« Adresse d'un site ou d'un flux ») et le README ; vérifier le rendu

## 3. Vérification

- [x] 3.1 Essayer cinq sites réels (blog WordPress, Ghost, Hugo, site d'actualité, site sans flux) et noter le résultat dans la PR ; `openspec validate discover-feed-from-site --strict` passe

## Workflow follow-up

- Archiver le changement une fois la PR fusionnée, avec synchronisation de `feed-subscriptions`.
