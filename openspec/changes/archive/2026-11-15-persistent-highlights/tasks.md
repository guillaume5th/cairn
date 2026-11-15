# Tasks

## 1. Citations de la note

- [x] 1.1 `Library.quotes(in:)` dans CairnCore : un passage par bloc de lignes `>` consécutives, lignes jointes par une espace, texte hors citation ignoré ; tests dans `QuoteTests` (note vide, deux blocs, `>` sans espace, aller-retour avec `appendQuote`), `swift test` vert

## 2. Surbrillance dans le lecteur

- [x] 2.1 `HTMLView` : paramètre `quotes`, `quoteScript` dans `.defaultClient` (texte replié à travers les nœuds, une marque `data-cairn-quote` par nœud traversé, première occurrence, nettoyage des anciennes marques), lancé après le chargement et sur changement de `quotes` ; couleur propre en clair et sombre ; vérifier dans Cairn Dev qu'un passage avec un lien sur deux paragraphes est surligné en entier
- [x] 2.2 `ArticleDetailView` passe `Library.quotes(in: article.note)` ; vérifier dans Cairn Dev : surligné juste après ⇧⌘H, encore à la réouverture, retiré quand la citation est effacée de la note, intact après une recherche effacée

## 3. Trouver la fonction

- [x] 3.1 Bouton « Surligner » (symbole `highlighter`, `.help`) dans le groupe de lecture d'`ArticleDetailView`, via `QuoteButtons` (menu des cairns pour un article non gardé avec plusieurs cairns) ; version grisée dans `DisabledReadingButtons` ; vérifier dans Cairn Dev que la barre ne change pas de disposition entre un article, plusieurs et aucun
- [x] 3.2 Indication « Sélectionnez un passage puis ⇧⌘H pour le citer ici » sur la note vide de `KeptEditor`, sans bloquer la saisie ; vérifier qu'elle disparaît à la première frappe

## 4. Vérification

- [x] 4.1 Scénarios de la spec dans Cairn Dev (dont citation introuvable et barre d'outils sans article) ; `swift test` vert et `BUILD SUCCEEDED`
