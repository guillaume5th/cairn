# Design

## Context

`ArticleListView` affiche la liste filtrée (`visibleArticles`) avec une sélection liée à `ContentView` : poser une seule sélection mémorise l'article et le marque lu. Voir proposal.md.

## Goals / Non-Goals

**Goals:** un seul geste clavier, sans conflit avec la saisie.

**Non-Goals:** passer à l'abonnement suivant quand la liste n'a plus de non lu (NetNewsWire) ; raccourcis j/k (les flèches existent) ; commande de menu (une touche sans modificateur dans un menu volerait la saisie dans les notes et la recherche).

## Decisions

- **`Library.nextUnread(after:in:)`** dans `CairnCore` : premier non lu après l'index courant, puis depuis le début, en excluant l'article courant ; testé.
- **`.onKeyPress(keys: [.space, "n"])` sur la `List`** : ne s'applique que quand la liste a le focus, donc ni dans l'article (WebKit fait défiler) ni dans un champ. Ignoré en mode sélection. Il pose la sélection par le même `Binding` qu'un clic, d'où le marquage lu et la mémoire par entrée.
- **Défilement** : `ScrollViewReader` autour de la `List`, `scrollTo(id)` vers l'article ouvert.
- **Rien à lire** : `NSSound.beep()`.

## Risks / Trade-offs

- [Un article ouvert sous le filtre « Non lus » disparaît-il de la liste ?] → non : `settleArticle` ne retire pas l'article courant pendant la lecture (comportement existant).
