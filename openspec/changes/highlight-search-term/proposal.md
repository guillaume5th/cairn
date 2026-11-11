# Proposal

## Why

La recherche filtre la liste, mais rien n'indique où le terme apparaît : pour un article trouvé par son contenu, sa note ou un tag, on ne voit pas pourquoi il est dans les résultats, et une fois l'article ouvert, il faut relire le texte pour retrouver le passage.

## What Changes

- Pendant une recherche, le terme est surligné dans le titre de chaque ligne de la liste.
- Quand le terme n'est pas dans le titre, la ligne affiche un court extrait autour de sa première occurrence dans le contenu, la note ou les tags, terme surligné (à la manière de Mail).
- Dans l'article affiché, toutes les occurrences sont surlignées dans le titre et le contenu, et l'article défile jusqu'à la première.
- Le surlignage suit la même règle que la recherche : sans tenir compte de la casse ni des accents.
- Sans recherche en cours, la liste et l'article s'affichent comme aujourd'hui.
- Les scripts des articles restent désactivés : le surlignage du contenu est fait par l'application elle-même.

## Capabilities

### New Capabilities
<!-- Aucune. -->

### Modified Capabilities
- `article-reading` : ajout d'une exigence de surlignage du terme recherché dans la liste et dans l'article affiché. L'exigence « Rechercher dans la liste courante » reste inchangée.

## Impact

- **Code** : `CairnCore` (`Library` : extrait autour de la première occurrence, testé) ; `App/ContentView.swift` (ligne de la liste, terme transmis à l'article) ; `App/ArticleDetailView.swift` (titre surligné) ; `App/HTMLView.swift` (surlignage et défilement dans le contenu).
- **Sécurité** : le script de surlignage est celui de l'application, exécuté dans son propre monde JavaScript ; la politique actuelle (aucun script de l'article, aucun contenu distant hors images) ne change pas.
- **Dépendances** : aucune nouvelle.
