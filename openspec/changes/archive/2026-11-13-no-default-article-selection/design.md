# Design

## Context

Dans `App/ContentView.swift`, deux endroits choisissent le premier article :
- `displayedArticleID` renvoie l'article mémorisé de l'entrée s'il est encore dans ses articles, sinon `visibleArticles.first`.
- `settleArticle()`, appelé au lancement et à chaque changement d'entrée, remplace un article mémorisé qui n'est plus visible par le premier visible, et l'écrit dans la mémoire.

Le volet sans article affiche déjà `ContentUnavailableView("Aucun article sélectionné")` avec `DisabledReaderToolbar`. Les résumés passent par `displayedDigest`, qui n'est pas concerné.

## Goals / Non-Goals

**Goals:**
- Plus aucun article choisi à la place de l'utilisateur, en gardant la mémoire par entrée telle quelle.

**Non-Goals:**
- Changer la sélection par défaut des résumés quotidiens (le plus récent reste affiché).
- Changer le format ou la persistance de `SelectionMemory`.

## Decisions

- **`displayedArticleID` renvoie `nil` sans article mémorisé** au lieu de `visibleArticles.first`. Le volet tombe alors dans sa branche existante « Aucun article sélectionné ». Pas de nouvelle vue.
- **`settleArticle()` efface la mémoire au lieu de la remplacer** : à l'ouverture d'une entrée, un article mémorisé qui n'est plus visible est oublié (`nil`) plutôt que remplacé par le premier. Alternative écartée : garder la mémoire et masquer seulement l'article ; un article encore présent mais filtré (« Non lus ») serait alors affiché sans être dans la liste, ce que `settleArticle` évitait justement. La règle « pas fait pendant la lecture » reste : on n'agit qu'à l'ouverture d'une entrée.
- **Vue de plusieurs abonnements** : `multiFeedArticle` suit le même `displayedArticleID`, donc aucun article par défaut non plus, sans code dédié.

## Risks / Trade-offs

- [Le clavier : sans sélection, ↓ dans la liste doit sélectionner le premier article] → comportement natif de la `List` ; à vérifier à la main.
- [Un article mémorisé filtré est oublié et non retrouvé quand on retire le filtre] → même comportement qu'aujourd'hui, où il était remplacé par le premier.
