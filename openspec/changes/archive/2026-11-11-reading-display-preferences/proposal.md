# Proposal

## Why

La taille du texte des articles est fixe (15 px pour le contenu), ce qui fatigue la lecture sur grand écran ou à distance. Et l'icône de la source sur chaque ligne de la liste d'articles prend de la place qu'on peut préférer donner aux titres, alors qu'elle n'est pas désactivable.

## What Changes

- Le menu Présentation propose « Agrandir le texte » (⌘+), « Réduire le texte » (⌘−) et « Taille normale » (⌘0). La taille s'applique à tout le panneau de lecture : titre, ligne source et date, contenu. Elle est bornée par un minimum et un maximum.
- Le menu Présentation propose une case « Icônes dans la liste d'articles », cochée par défaut. Décochée, les lignes de la liste d'articles n'affichent plus l'icône de la source. La barre latérale et l'en-tête de l'article gardent leurs icônes, et la pastille bleue des non lus reste.
- Les deux réglages sont conservés d'un lancement à l'autre, sur ce Mac.
- Pas de fenêtre Réglages : le menu Présentation suffit pour deux réglages.

## Capabilities

### New Capabilities
<!-- Aucune. -->

### Modified Capabilities
- `article-reading` : ajout d'une exigence de taille du texte du panneau de lecture, réglable et conservée.
- `feed-icons` : l'icône sur les lignes de la liste d'articles devient désactivable ; la barre latérale et l'en-tête de l'article restent inchangés.

## Impact

- **Code** : `App/CairnApp.swift` (commandes du menu Présentation) ; `App/ArticleDetailView.swift` (taille du titre et de la ligne source) ; `App/HTMLView.swift` (taille du contenu) ; `App/ContentView.swift` (icône des lignes de la liste).
- **Données** : deux préférences locales (UserDefaults), pas de changement du modèle ni de la synchro.
- **Dépendances** : aucune nouvelle.
