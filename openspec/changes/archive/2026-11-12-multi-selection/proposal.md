# Proposal

## Why

Toutes les actions de Cairn portent aujourd'hui sur un seul élément à la fois : garder dix articles, en marquer vingt comme lus, ranger cinq abonnements dans un dossier ou effacer une semaine de résumés demande autant de clics que d'éléments. La sélection multiple, standard sur macOS (⌘-clic, ⇧-clic, ⌘A), permet d'agir sur un lot d'un seul geste.

## What Changes

- **Articles** : sélection de plusieurs articles dans toutes les listes (« Tous les articles », abonnement, dossier, cairn, tag). Le clic droit et les boutons du volet de lecture s'appliquent alors à toute la sélection : garder dans un cairn (ou y déplacer), retirer du cairn, marquer lu ou non lu, ouvrir dans le navigateur, supprimer des articles orphelins. Une seule confirmation pour le lot quand une confirmation est requise.
- **Résumés** : sélection de plusieurs résumés et suppression du lot (clic droit, touche Supprimer, corbeille), avec une seule confirmation.
- **Abonnements** : sélection de plusieurs abonnements dans la barre latérale ; leurs articles sont listés ensemble, comme pour un dossier. Déplacement du lot vers un dossier (menu ou glisser-déposer) et suppression du lot avec une seule confirmation. Les autres entrées (« Tous les articles », dossiers, cairns, tags, « Résumés ») restent en sélection simple.
- **Volet de lecture** : avec plusieurs éléments sélectionnés, il affiche « N articles sélectionnés » (ou « N résumés sélectionnés ») et les actions communes, comme Mail. Les articles d'une sélection multiple ne sont pas marqués lus automatiquement.
- La mémoire de sélection (par entrée et entre les lancements) reste à un seul élément : une sélection multiple n'est pas retenue.

## Capabilities

### New Capabilities
_Aucune._ La sélection multiple étend les capacités existantes.

### Modified Capabilities
- `article-reading` : sélection de plusieurs articles, affichage d'une sélection multiple dans le volet de lecture, marquage lu ou non lu du lot, ouverture du lot dans le navigateur.
- `cairn` : garder, déplacer, retirer et supprimer (orphelins) plusieurs articles à la fois.
- `feed-subscriptions` : sélection de plusieurs abonnements, déplacement et suppression du lot.
- `daily-digest` : sélection et suppression de plusieurs résumés.

## Impact

- App uniquement (`ContentView`, `ArticleDetailView`, `SidebarView`, `DigestViews`) : sélections passant d'un identifiant à un ensemble, menus contextuels de sélection, vue « N sélectionnés ».
- `CairnCore` : variantes « lot » de quelques opérations de `Library` si nécessaire (garder, retirer, supprimer), testées comme les opérations unitaires. Aucun changement de modèle ni de données.
- Aucune nouvelle dépendance.
