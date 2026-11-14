# Design

## Context

`AppState.refresh` appelle `Library.refreshAll`, qui ingère chaque flux. Les notifications existantes (résumé du jour) passent par `DigestNotifications` : autorisation commune, identifiant du résumé dans `userInfo`, clic transmis à `AppState.digestToOpen`. Voir proposal.md.

## Goals / Non-Goals

**Goals:** une notification par abonnement choisi qui a du nouveau, qui mène à cet abonnement.

**Non-Goals:** filtre par mot-clé ; regroupement en une seule notification ; notifications par dossier ; heures de silence (le mode Concentration de macOS s'en charge).

## Decisions

- **`refreshAll` renvoie, par abonnement, le nombre d'articles ajoutés** (`[Feed: Int]`, sans les zéros). `ingest` le calcule déjà ; l'app décide quoi notifier. `@discardableResult` garde les appels existants.
- **Corps : le titre du plus récent article ajouté quand il y en a un, sinon « N nouveaux articles » suivi de ce titre.** Le plus récent est pris parmi les articles de l'abonnement par date de publication.
- **Clic : l'identifiant de l'abonnement dans `userInfo` (clé `feed`)**, transmis à `AppState.feedToOpen` ; `ContentView` sélectionne l'abonnement, comme pour un résumé.
- **Autorisation demandée en activant l'option**, au cas où l'utilisateur aurait coupé le badge (seul autre déclencheur de la demande).

## Risks / Trade-offs

- [Notifications refusées dans Réglages Système] → rien n'est posté ; l'option reste cochée sans effet, comme pour le résumé.
