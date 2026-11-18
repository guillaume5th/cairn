# Design

## Context

La liste d'articles est calculée dans `ContentView.visibleArticles` : articles de l'entrée choisie, puis `Library.search(searchText, in:)` (texte sur titre, contenu, note, tags), puis le filtre « Non lus » du bouton de la liste. Le champ est un `.searchable(text:placement: .toolbar)`, vidé quand l'entrée change. La vue des résumés quotidiens a son propre `.searchable`. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Jetons natifs, logique de filtrage testable dans CairnCore, aucune nouvelle donnée persistée.

**Non-Goals:**
- Jetons mémorisés entre les lancements ou par entrée, recherches enregistrées.

## Decisions

- **API native** : `.searchable(text:tokens:placement:prompt:token:)` pour les jetons, et `.searchSuggestions { … .searchCompletion(token) }` pour les proposer. SwiftUI transforme la proposition choisie en jeton et retire le texte tapé. Constaté dans Cairn Dev : la variante `suggestedTokens:`, censée générer les propositions, n'en affiche aucune pour un champ placé dans la barre d'outils sur macOS ; `searchSuggestions` les affiche. Alternative écartée : analyser le texte (`source:x`) à la main, qui donne un champ moins lisible et des cas d'analyse (espaces, guillemets).
- **Type `SearchToken` dans CairnCore** : `enum { source(feedID), tag(key), unread, kept }`, `Identifiable`, avec le libellé affiché (titre du flux, nom du tag), porté par le jeton lui-même. La source se reconnaît à l'identifiant persistant du flux, pas à son titre, pour que deux flux homonymes restent distincts ; un article dont l'abonnement a été supprimé ne correspond à aucun jeton de source. Le tag porte sa `key` (insensible à la casse et aux accents, comme `Library.tagKey`), ce qui regroupe un même tag dans plusieurs cairns.
- **Filtrage pur** : `Library.filter(_ articles:, tokens:)` regroupe les jetons par type, OU à l'intérieur d'un type, ET entre types. Appliqué dans `visibleArticles` avant `Library.search`, donc la recherche texte, le bouton « Non lus » et le surlignage restent inchangés. Le jeton « Non lus » et le bouton se cumulent (aucun ne pilote l'autre) : plus simple, et le résultat est le même.
- **Suggestions pures** : `Library.suggestedTokens(for text:, in articles:)` calculées sur la liste de l'entrée avant jetons et texte. Préfixe `source:` ou `tag:` : seuls ce type, filtré par la suite du texte. Sinon : sources et tags dont le nom contient le texte (casse et accents ignorés), plus « Non lus » et « Gardés » s'ils correspondent ; texte vide : aucune proposition (le champ reste discret). Jetons déjà présents exclus, liste limitée à 10.
- **Champ par vue** : seule la liste d'articles reçoit les jetons ; `DigestListView` garde son `.searchable(text:)`. Les jetons sont un `@State` de `ContentView`, vidé dans les mêmes `onChange` que `searchText`.

## Risks / Trade-offs

- [Abonnement renommé ou supprimé pendant la recherche] → le jeton garde le titre qu'il avait et, si le flux a disparu, ne correspond plus à rien, comme une recherche sans résultat ; il disparaît au changement d'entrée.
- [Coût du calcul des suggestions à chaque frappe] → parcours linéaire des articles déjà en mémoire, comme `Library.search` ; même raccourci assumé.
- [Comportement exact du clavier dans les propositions sur macOS (Tab, flèches)] → laissé à SwiftUI ; vérifié dans Cairn Dev.
