# Design

## Context

Le volet de lecture d'une sélection multiple (`ArticleSelectionView`) affichait `DisabledReaderToolbar`, qui grise tous les boutons. Les actions de la sélection étaient dans `SelectionActions`, une capsule flottante en `safeAreaInset` sous la liste d'articles. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Garder la même disposition de la barre du volet, qu'il affiche un article, une sélection ou aucun article.

**Non-Goals:**
- Changer l'emplacement du champ de recherche, du bouton Rafraîchir ou de la barre du volet. Ces pistes ont été essayées puis abandonnées : avec la barre latérale masquée, le champ de recherche disparaissait et Rafraîchir passait dans le menu de débordement.
- Changer le comportement natif du ⇧-clic dans la liste.

## Decisions

- **Barre d'outils propre à `ArticleSelectionView`, au lieu de `DisabledReaderToolbar`.** Elle reprend les six boutons de lecture dans le même ordre. `KeepButton`, marquer lu/non lu et ouvrir dans le navigateur sont actifs, et inactifs sans article sélectionné. Les confirmations (`unkeepConfirmation`, `openConfirmation`) sont portées par ce volet. `DisabledReaderToolbar` reste utilisé quand aucun article n'est sélectionné.
- **Pas de bouton Supprimer dans la barre.** La suppression ne concerne que les articles sans abonnement, un cas rare ; un bouton qui n'apparaît que dans ce cas ferait bouger la barre. Elle reste dans `ArticleMenuItems` (menu contextuel) et `onDeleteCommand` (touche Supprimer) de la liste.
- **Suppression de `SelectionActions` et de son `safeAreaInset`.** Rien ne recouvre plus la liste.

## Risks / Trade-offs

- [La suppression d'articles sans abonnement n'a plus de bouton visible] → menu contextuel et touche Supprimer, comme pour un seul article.
- [Pas de test automatisé de l'interface] → vérification manuelle sur captures de l'app lancée, voir tasks.md.
