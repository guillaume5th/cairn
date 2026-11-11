# Proposal

## Why

Avec beaucoup d'abonnements, la barre latérale devient une longue liste plate : impossible de regrouper ses sources par thème ni de lire d'un coup tous les articles d'un même sujet. Les fichiers OPML des autres lecteurs contiennent déjà ces dossiers, mais Cairn les ignore à l'import.

## What Changes

- L'utilisateur peut créer des dossiers d'abonnements (un seul niveau, pas de sous-dossiers) depuis le « + » de la section Abonnements, qui propose désormais « Ajouter un abonnement… » et « Nouveau dossier… ».
- Un abonnement est dans au plus un dossier. On le range par glisser-déposer sur un dossier, ou par clic droit > « Déplacer vers » (avec « Aucun dossier » pour le ramener à la racine).
- Dans la barre latérale, un dossier se replie, affiche le total de non lus de ses abonnements, et sa sélection liste les articles de tous ses abonnements. Les abonnements hors dossier restent à la racine de la section.
- Clic droit sur un dossier : « Renommer… » et « Supprimer le dossier ». La suppression garde les abonnements et leurs articles, remis à la racine.
- La vue d'un dossier se comporte comme celle d'un abonnement : recherche, filtre « Non lus », sélection par défaut et sélection mémorisée.
- **BREAKING (comportement)** : l'import OPML ne met plus les flux à plat ; il recrée les dossiers. L'export OPML écrit les dossiers.

## Capabilities

### New Capabilities
<!-- Aucune. -->

### Modified Capabilities
- `feed-subscriptions` : ajout des dossiers (création, classement, renommage, suppression) ; l'import et l'export OPML conservent les dossiers au lieu de les ignorer.
- `article-reading` : ajout de la vue d'un dossier (liste des articles de ses abonnements, avec recherche, filtre et sélection comme les autres entrées).

## Impact

- **Données** : nouveau modèle `Folder` (SwiftData, compatible CloudKit) et relation optionnelle `Feed.folder`. Les abonnements existants n'ont pas de dossier : aucune migration manuelle.
- **Code** : `CairnCore` (`Models`, `OPML` parse/export avec dossiers, `Library` import/export et opérations sur les dossiers, tests) ; `App/SidebarView.swift` (section Abonnements, menu « + », glisser-déposer, menus contextuels) ; `App/ContentView.swift` (`SidebarItem.folder`, liste et titre de la vue dossier, mémoire de sélection).
- **Dépendances** : aucune nouvelle.
