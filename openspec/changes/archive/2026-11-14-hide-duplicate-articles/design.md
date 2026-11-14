## Context

`Library.ingest` dédoublonne déjà par abonnement (`externalID`). Entre abonnements, rien : un même lien donne deux `Article`, deux lignes, deux non lus. Les vues sont filtrées en mémoire dans `ContentView.visibleArticles` ; les compteurs (`Feed.unreadCount`, la `@Query` des non lus de `SidebarView`, le badge du Dock) comptent `isRead`.

## Goals / Non-Goals

**Goals :** une ligne par lien dans les vues multi-abonnements ; un doublon ne compte pas comme non lu ; un doublon ne pèse pas deux fois dans le résumé.

**Non-Goals :** fusionner les articles en base ; synchroniser l'état lu dans les deux sens après coup ; détecter des doublons par titre ou contenu ; migrer les doublons déjà en base (la purge les fera disparaître).

## Decisions

- **Le doublon naît lu, à l'ingestion.** Plutôt que de propager `isRead` à chacun des cinq endroits qui le modifient (sélection, barre d'outils, lot, « Tout marquer comme lu », barre latérale), `ingest` crée lu un article dont le lien normalisé existe déjà ailleurs. Lire l'original suffit donc, et tous les compteurs restent justes sans changement. Limite acceptée : remettre l'original en non lu ne touche pas la copie.
- **Recherche des liens connus :** un `Set` des liens normalisés de tous les articles, calculé une fois par rafraîchissement dans `refreshAll` et passé à `ingest` (paramètre avec défaut vide pour les appels existants) ; `ingest` y ajoute chaque lien inséré, ce qui couvre deux flux apportant le même lien dans le même rafraîchissement.
- **Normalisation** (`Library.linkKey(_:) -> String?`, `nil` pour un lien vide ou invalide) : via `URLComponents`, schéma ignoré, hôte en minuscules sans `www.`, chemin sans `/` final, fragment retiré, paramètres `utm_*` retirés, autres paramètres conservés dans leur ordre.
- **Affichage :** `Library.withoutDuplicates(_ articles: [Article]) -> [Article]` garde l'ordre d'entrée et, par clé, un seul exemplaire : gardé, sinon non lu, sinon le premier rencontré (le plus récent, la liste étant triée par date décroissante). Appliqué dans `visibleArticles` aux cas `.all`, `.today`, `.folder` et multi-abonnements, avant la recherche et le filtre « Non lus ». Pas aux cas `.feed`, `.cairn`, `.tag`.
- **Résumé :** `digestArticles` passe par `withoutDuplicates`.

## Risks / Trade-offs

- [Deux URLs différentes pour le même article (AMP, redirections, autre paramètre de suivi)] → non détectées ; acceptable, à étendre dans `linkKey` si besoin.
- [Un paramètre de requête significatif identique sauf l'ordre] → traité comme deux liens ; rare.
- [Le calcul du `Set` parcourt tous les articles à chaque rafraîchissement] → quelques milliers d'articles au plus grâce à la purge ; négligeable.
- [Copie déjà lue dans la vue de son abonnement alors que l'utilisateur ne l'y a pas ouverte] → voulu : c'est le même article.
