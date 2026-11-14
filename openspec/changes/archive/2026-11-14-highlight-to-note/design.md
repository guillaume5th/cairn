# Design

## Context

Le volet de lecture affiche l'article dans un `WebView`/`WebPage` SwiftUI (`App/HTMLView.swift`) avec le JavaScript du flux désactivé ; l'app exécute déjà son propre script dans `.defaultClient` pour surligner le terme recherché. La note est `Article.note` (texte libre, éditée dans `KeptEditor`, enregistrée sans action). Garder passe par `Library.keep(_:in:)` ; `KeepButton` applique déjà la règle « un cairn : direct, plusieurs : menu ».

## Goals / Non-Goals

**Goals:**
- Un geste pour envoyer la sélection dans la note, au clavier comme à la souris.

**Non-Goals:**
- Surbrillance persistante, ancrage des passages dans l'article, liste de surlignages distincte de la note.
- Citation depuis la vue d'une sélection multiple ou depuis le résumé IA.

## Decisions

- **Lire la sélection avec un script de l'app** : `page.callJavaScript("return window.getSelection().toString()", contentWorld: .defaultClient)`, comme `highlightScript`. Le JS du flux reste désactivé. Alternative écartée : copier via le presse-papiers (efface celui de l'utilisateur).
- **Mise en forme dans CairnCore** : `Library.appendQuote(_ passage: String, to note: String) -> String` — passage rogné (espaces, lignes vides en bord), chaque ligne préfixée par `> `, ligne vide avant si la note n'est pas vide. Fonction pure, testée dans `CairnCoreTests` ; un passage vide renvoie la note inchangée.
- **Menu Édition plutôt que menu Article** : le menu Article reprend exactement le menu contextuel d'une ligne de liste (spec `article-reading`) ; « Surligner » agit sur une sélection de texte, comme Copier, donc il va dans `CommandGroup(after: .textEditing)` à côté de « Rechercher ». ⇧⌘H n'est pas utilisé dans l'app.
- **Relier menu et lecteur par une `FocusedValue`** : `HTMLView` publie (via `focusedSceneValue`) une action asynchrone qui renvoie la sélection courante ; `ArticleDetailView` l'enveloppe avec l'article affiché et les cairns. Pas de nouvel état global dans `AppState`.
- **Grisage** : savoir s'il y a une sélection demande un aller-retour JS. Le menu Édition reste actif dès qu'un article est affiché ; sans sélection, l'action ne fait rien (bip système). Griser selon la sélection est remis à plus tard, si `WebPage` expose un état de sélection observable.
- **Pas de menu contextuel du texte (repli appliqué)** : la seule API, `webViewContextMenu` (SwiftUI WebKit), remplace tout le menu natif — vérifié dans Cairn Dev : Copier, Rechercher et les actions des liens disparaissent. « Surligner » reste donc dans le menu Édition avec ⇧⌘H.
- **Garder d'abord** : un cairn → `Library.keep` dans ce cairn ; plusieurs → sous-menu des cairns, et ⇧⌘H ne fait rien sur un article non gardé (pas de choix implicite de cairn).

## Risks / Trade-offs

- [Pas de « Surligner » au clic droit] → Accepté : le menu Édition et ⇧⌘H couvrent le geste ; à revoir si WebKit permet d'ajouter un élément au menu natif.
- [Le texte sélectionné perd la mise en forme (liens, gras)] → Accepté : la note est du texte libre.
- [Une sélection hors de l'article (titre SwiftUI, résumé) n'est pas lue] → Accepté : seule la sélection dans le `WebView` compte.
