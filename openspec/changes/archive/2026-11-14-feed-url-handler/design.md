# Design

## Context

« Ajouter un abonnement » est une alerte de `ContentView` (champ `newFeedURL`), qui passe l'adresse à `AppState.addFeed` : normalisation (schéma manquant → https), découverte, choix entre plusieurs flux. L'app n'a qu'une fenêtre (`Window`). Voir proposal.md.

## Goals / Non-Goals

**Goals:** un lien `feed:` mène à l'ajout, sans contourner la confirmation ni la découverte.

**Non-Goals:** extension Safari ; schéma `feeds:` ; abonnement sans confirmation.

## Decisions

- **Deux formes reconnues.** `feed:https://x/rss` (adresse complète après `feed:`) et `feed://x/rss` (l'hôte suit, sans schéma) ; la seconde devient `x/rss` et la normalisation existante ajoute https. Fonction pure dans `CairnCore`, testée.
- **`onOpenURL` sur `ContentView` pré-remplit l'alerte et l'ouvre.** L'utilisateur voit l'adresse avant de s'abonner. Alternative écartée : s'abonner directement, sans voir ce qu'un lien a déclenché.
- **`CFBundleURLTypes` dans `project.yml`.** macOS enregistre le schéma à l'installation de l'app ; l'utilisateur peut choisir Cairn comme lecteur par défaut s'il en a plusieurs.

## Risks / Trade-offs

- [Un autre lecteur déjà installé reste celui du schéma] → macOS choisit ; Cairn n'impose rien.
