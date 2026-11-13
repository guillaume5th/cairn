# Proposal

## Why

Les trois barres du volet de lecture (un article, une sélection, aucun article) ont été regroupées en une seule, pour qu'elles ne puissent plus se désynchroniser. Ce regroupement change deux comportements visibles, à inscrire dans la spec : l'un la contredit (Partager actif avec un seul article coché), l'autre la complète (le bouton Marquer d'un article seul bascule).

## What Changes

- Quand exactement un article est sélectionné en mode sélection, « Partager » est actif et partage cet article. Avec plusieurs articles, il reste grisé.
- Pour un article affiché seul, le bouton « Marquer » bascule comme pour une sélection : « Marquer comme lu » si l'article est non lu, sinon « Marquer comme non lu ». Avant, il proposait toujours « Marquer comme non lu ».

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : « Barre d'outils du volet sans article » (Partager actif avec un seul article sélectionné) et « État lu / non lu » (remettre un article affiché en lu depuis la barre).

## Impact

- `App/ArticleDetailView.swift` : un seul composant `ReaderToolbar` pour les trois états du volet.
- Livrés dans le même commit, sans effet sur les exigences : la surbrillance native des lignes cochées en mode sélection, le point non lu et les liens des articles à la couleur d'accent, le code des articles en police à chasse fixe du système, et le retrait de la reconstruction de la liste à chaque arrivée d'articles (le bug de hauteur qu'elle contournait ne se reproduit plus).
- Aucun impact sur `CairnCore` ni les données.
