# Tasks

## 1. Logique dans CairnCore

- [x] 1.1 Ajouter `Library.neighbor(of:in:offset:)` et vérifier avec des tests : suivant, précédent, premier sans article courant, nil au début et à la fin, liste vide (`swift test --only-use-versions-from-resolved-file`)
- [x] 1.2 Ajouter `Library.lastUsedCairn(context:)` et vérifier avec des tests : cairn de l'article de plus grand `keptAt`, premier par nom sans article gardé, nil sans cairn

## 2. Touches de la liste

- [x] 2.1 Dans `ArticleListView`, gérer `j`, `k` (sélection, défilement, son au bout) et `s` (garder dans `lastUsedCairn` ou retirer via `KeepButton.unkeep`) à côté d'Espace et N, ignorés en mode sélection ; vérifier que le build passe
- [x] 2.2 Vérifier dans Cairn Dev avec `cairn-run` : `k` avance et `j` recule en marquant lu, son au bout, `s` garde dans le dernier cairn puis retire, confirmation pour un article annoté, rien en mode sélection
