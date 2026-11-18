# Proposal

## Why

La recherche de la liste d'articles ne filtre que par texte libre : on ne peut pas dire « les articles de Korben non lus » ou « mes articles gardés tagués swift » sans changer de vue. macOS propose des jetons de recherche natifs (comme Mail et le Finder), qui rendent ces filtres visibles et combinables dans le champ de recherche.

## What Changes

- Le champ de recherche des listes d'articles accepte des jetons : une source (abonnement), un tag, « Non lus », « Gardés ».
- Pendant la frappe, le champ propose les jetons qui correspondent au texte (sources et tags présents dans la liste affichée, et les deux jetons fixes) ; le préfixe `source:` ou `tag:` restreint les propositions à ce type.
- Les jetons se combinent entre eux et avec le texte recherché : deux jetons du même type élargissent (une source ou l'autre), deux types différents restreignent.
- Changer d'entrée dans la barre latérale vide les jetons comme le texte.
- La vue « Résumés quotidiens » garde la recherche par texte seul.

## Capabilities

### New Capabilities

### Modified Capabilities
- `article-reading`: ajout d'une exigence « Filtrer par jetons de recherche » à côté de « Rechercher dans la liste courante » ; le scénario « Changement d'entrée » de cette dernière s'étend aux jetons.

## Impact

- `CairnCore` : un type de jeton et une fonction pure de filtrage (et de suggestions), avec leurs tests.
- `App/ContentView.swift` : `.searchable(text:tokens:suggestedTokens:…)` à la place de `.searchable(text:)` pour la liste d'articles, et remise à zéro des jetons au changement d'entrée.
- Aucune dépendance ajoutée, aucun changement du modèle de données.
- Hors périmètre : jetons de date, recherches enregistrées (une autre idée du backlog), jetons dans les résumés quotidiens.
