# Design

## Context

- Le contenu est rendu par `HTMLView` avec un CSS fixe (`font-size: 15px`). La page est rechargée par `.task(id: html)`.
- L'en-tête d'`ArticleDetailView` utilise `.title2.bold()` pour le titre et la police par défaut pour la ligne source ; l'icône de l'en-tête (`SourceIcon` sans taille fixe) suit la taille du texte qu'elle accompagne.
- Les lignes de la liste (`ArticleListView`) affichent `SourceIcon(side: SourceIcon.articleRowSide)`.
- macOS n'applique pas Dynamic Type aux polices de texte SwiftUI : `.dynamicTypeSize` ne suffit pas à agrandir l'en-tête.

## Goals / Non-Goals

**Goals :** une seule valeur d'échelle pour tout le panneau de lecture ; des commandes de menu natives avec raccourcis et état désactivé aux bornes.

**Non-Goals :**
- Taille du texte de la liste d'articles ou de la barre latérale.
- Taille de l'éditeur de note et de tags (ils gardent la taille système).
- Fenêtre Réglages.

## Decisions

### Une échelle stockée dans `@AppStorage`
`@AppStorage("articleTextScale")` (Double, défaut 1,0) et `@AppStorage("showListIcons")` (Bool, défaut vrai), lus par les commandes et par les vues. `@AppStorage` est observé partout où il est lu : le changement depuis le menu met les vues à jour sans état partagé supplémentaire.
- *Alternative : propriété d'`AppState`.* Écartée : il faudrait la persister à la main ; `@AppStorage` le fait déjà.

### Paliers réguliers bornés
Pas de 0,1 entre 0,8 et 2,0 (soit 12 px à 30 px pour le contenu), arrondis au dixième : ⌘+ puis ⌘− revient exactement à la taille de départ et les bornes sont atteintes pile. Les commandes sont désactivées aux bornes, « Taille normale » à 1,0.
- *Alternative : paliers multiplicatifs (×1,1).* Écartée : la montée et la descente ne repassent pas par les mêmes valeurs, et les bornes ne tombent pas juste.

### Application de l'échelle
- **Contenu** : la taille de base du CSS devient `15 × échelle` px ; l'identifiant de la tâche de chargement inclut l'échelle pour recharger la page quand elle change.
- **En-tête** : polices système explicites multipliées par l'échelle (titre 17 pt × échelle en gras, ligne source 13 pt × échelle), les tailles de `.title2` et `.body` sur macOS. L'icône de l'en-tête suit la police, donc l'échelle.
- *Alternative : zoom de la WebView (`pageZoom`).* Écartée : il ne couvre pas l'en-tête SwiftUI, et deux mécanismes différents risquent de ne pas grandir au même rythme.

### Icônes de la liste
La ligne n'insère `SourceIcon` que si `showListIcons` est vrai. La pastille des non lus reste en tête de ligne.

## Risks / Trade-offs

- [Le rechargement de la page à chaque palier remet le défilement de l'article en haut] → Acceptable pour un réglage ponctuel ; à revoir avec une mise à jour CSS sans rechargement si c'est gênant.
- [Les tailles de base 17 pt et 13 pt reproduisent les styles macOS actuels ; si le système les change, l'en-tête à l'échelle 1 diffère légèrement] → Écart minime, sans effet fonctionnel.

## Migration Plan

Aucune : sans préférence enregistrée, échelle 1,0 et icônes affichées, soit le comportement actuel.
