# Proposal

## Why

Aujourd'hui, changer d'entrée dans la barre latérale vide la sélection d'article : le panneau de lecture affiche « Aucun article sélectionné » et, en revenant sur une vue déjà parcourue, il faut retrouver à la main l'article où l'on en était. Au lancement, l'app s'ouvre aussi sans rien d'affiché.

## What Changes

- À l'ouverture d'une entrée de la barre latérale (« Tous les articles », « Cairn », un tag, un abonnement) qui n'a pas d'article mémorisé, le premier article de la liste est sélectionné et affiché.
- Chaque entrée retient le dernier article sélectionné ; en y revenant, cet article est de nouveau sélectionné.
- Si l'article mémorisé n'est plus dans la liste (filtre « Non lus », recherche, purge, suppression, désabonnement), le premier article de la liste est sélectionné à la place.
- L'entrée courante et les articles mémorisés sont conservés d'un lancement à l'autre.
- **BREAKING (comportement)** : un article n'est plus marqué lu du seul fait d'être affiché. Il l'est quand l'utilisateur le choisit (clic, flèches du clavier). Une sélection automatique (premier article, restauration) l'affiche sans changer son état lu.

## Capabilities

### New Capabilities
<!-- Aucune : la sélection d'article relève de la lecture des articles. -->

### Modified Capabilities
- `article-reading` : ajout d'une exigence de sélection par défaut et mémorisée par entrée ; l'exigence « État lu / non lu » ne marque plus lu qu'à la sélection explicite par l'utilisateur.

## Impact

- **Code** : `App/ContentView.swift` (sélection d'entrée et d'article, mémoire par entrée, persistance) ; `App/ArticleDetailView.swift` (marquage lu conditionné au choix de l'utilisateur).
- **Données** : préférences locales (UserDefaults) pour l'entrée courante et les articles mémorisés ; aucun changement du modèle SwiftData ni de la synchro CloudKit. La sélection reste propre à chaque Mac.
- **Dépendances** : aucune nouvelle.
