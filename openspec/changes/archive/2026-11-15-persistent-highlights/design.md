# Design

## Context

`HTMLView` charge l'article dans un `WebPage` (JS du flux désactivé) et exécute déjà le script de l'app `highlightScript` dans `.defaultClient` pour la recherche : il enveloppe les occurrences dans `<mark data-cairn>`, mais seulement à l'intérieur d'un nœud texte. « Surligner » (`QuoteAction`, `QuoteButtons`) ajoute la sélection à `Article.note` via `Library.appendQuote`. La barre d'outils du lecteur (`ReaderToolbar`) garde la même disposition dans tous les états (un article, plusieurs, aucun), avec `DisabledReadingButtons` pour les états sans article unique.

## Goals / Non-Goals

**Goals:**
- Surbrillance déduite de la note, recalculée à chaque changement de note.

**Non-Goals:**
- Stocker des ancres (position, contexte avant/après) : écarté, ce serait une seconde source de vérité et une migration.
- Distinguer deux occurrences identiques d'un passage : on prend la première.
- Bouton flottant près de la sélection, menu contextuel du texte (voir l'archive `highlight-to-note`).

## Decisions

- **Extraction dans CairnCore** : `Library.quotes(in note: String) -> [String]` — chaque bloc de lignes consécutives commençant par `>` (espace facultatif après) donne un passage, lignes jointes par une espace. Pure et testée ; c'est l'inverse de `appendQuote` (un aller-retour `appendQuote` → `quotes` rend le passage, espaces normalisés).
- **Un second script, monde `.defaultClient`** : `quoteScript` reçoit la liste des passages. Il retire ses anciennes marques (`mark[data-cairn-quote]`), parcourt les nœuds texte, construit un texte replié unique (casse, accents comme la recherche, sans aucun espace : les retours à la ligne de la sélection entre deux blocs n'existent pas dans les nœuds texte) avec, pour chaque caractère replié, son nœud et son offset, puis cherche chaque passage replié. Pour la plage trouvée, il enveloppe le morceau de chaque nœud texte traversé dans son propre `<mark>` : `surroundContents` échoue sur une plage qui coupe des éléments. Pas de défilement, contrairement à la recherche.
- **Attribut distinct** : `data-cairn-quote` (couleur propre, par ex. bleu pâle, adaptée au mode sombre) pour que le nettoyage de la recherche (`mark[data-cairn]`) ne touche pas aux citations, et inversement. Ordre fixe à chaque passage : retirer les citations, surligner la recherche, remettre les citations. La recherche ne cherche que dans un nœud texte et les marques de citation le coupent : sans cet ordre, « pseudo-standard web » n'était plus trouvé quand « web » commence une citation (vu dans Cairn Dev). Le défilement vers la recherche n'a lieu que quand la recherche change.
- **Alimentation** : `HTMLView` gagne `var quotes: [String] = []` ; `ArticleDetailView` passe `Library.quotes(in: article.note)`. Les scripts tournent après le chargement et sur `.onChange` de la recherche ou des citations — donc à chaque frappe dans la note quand les citations changent ; le coût est un parcours du DOM, négligeable pour un article.
- **Bouton de barre d'outils** : `QuoteButtons` prend un libellé avec le symbole `highlighter` et `.help`, pour servir dans le menu Édition et dans `ReaderToolbar` (le menu des cairns devient un `Menu` de barre d'outils). Placé dans le groupe de lecture d'`ArticleDetailView`, après « Résumer » ; `DisabledReadingButtons` reçoit le même bouton grisé pour que la disposition ne bouge pas. Raccourci ⇧⌘H uniquement sur la commande de menu, pour ne pas le déclarer deux fois.
- **Indication** : superposition d'un `Text` secondaire sur le `TextEditor` de `KeptEditor` quand `article.note.isEmpty`, sans intercepter les clics (`allowsHitTesting(false)`). `TextEditor` n'a pas de `prompt`.

## Risks / Trade-offs

- [Un passage court répété dans l'article est surligné à sa première occurrence, peut-être pas celle citée] → Accepté ; les citations sont en général assez longues pour être uniques.
- [Une citation modifiée à la main ne correspond plus] → Elle n'est simplement pas surlignée.
- [Le texte de l'article change (passage du flux à l'article complet)] → Le script tourne à chaque chargement ; un passage absent de la nouvelle version n'est pas surligné.
- [Comparer sans espaces peut faire correspondre « for mat » et « format »] → Négligeable pour un passage de quelques mots.
- [Une modification de la recherche et de la note au même instant peut entrelacer les trois passages] → Au pire, la recherche n'est pas surlignée jusqu'au changement suivant.
