# Design

## Context

Voir proposal.md pour le pourquoi. Aujourd'hui « garder » est porté par `Article.isKept`/`keptAt`/`cairn`, la purge (`Library.purge`) épargne `isKept`, et l'état lu est écrit directement (`article.isRead = …`) à une dizaine d'endroits de l'app (sélection, menus, « Tout marquer comme lu », marquer un abonnement ou un dossier comme lu). Le schéma doit rester compatible CloudKit : propriétés avec valeur par défaut ou optionnelles.

## Goals / Non-Goals

**Goals:**
- Une file distincte des cairns, qui se vide d'elle-même à la lecture, sans toucher aux nombreux endroits qui écrivent `isRead`.

**Non-Goals:**
- Expiration automatique de la file après N jours.
- Indexation Spotlight et export Markdown de la file (seuls les articles gardés y vont).
- Réordonner la file à la main.

## Decisions

### Une date `readLaterAt: Date?`, appartenance dérivée de l'état lu
`Article.readLaterAt` (nil par défaut, donc compatible CloudKit, sans migration). Un article est **dans la file** quand `readLaterAt != nil && !isRead`. La sortie à la lecture est donc gratuite : aucun des points qui écrivent `isRead` n'a à changer, y compris la synchronisation iCloud d'un autre Mac.
- Ajouter : `readLaterAt = now`, `isRead = false`. Retirer : `readLaterAt = nil`.
- Conséquence assumée (spec « Remettre en non lu ») : un article lu puis remis en non lu revient dans la file, à sa place (la date est conservée). C'est cohérent : « non lu » veut dire « encore à lire ».
- Alternative écartée : un booléen effacé à chaque passage en lu. Il faudrait intercepter toutes les écritures de `isRead` (ou un `didSet`, non fiable avec `@Model` et la synchro), pour un gain nul.
- `Library.readLater(_:now:)` et `Library.removeFromReadLater(_:)` comme pour `keep`/`unkeep`, et `Article.isQueued` (calculé, `@Transient` inutile) pour l'UI.

### Indépendant de « garder »
La file ne touche ni `isKept`, ni `cairn`, ni note, ni tags. Un article gardé peut aussi être dans la file ; garder un article de la file ne l'en retire pas (les deux intentions sont différentes : « à lire » vs « à conserver »).

### Purge
Le prédicat devient `!$0.isKept && ($0.readLaterAt == nil || $0.isRead) && $0.publishedAt < cutoff`. Un article lu de la file redevient purgeable normalement. À vérifier : `#Predicate` SwiftData accepte la comparaison d'un optionnel à `nil` (sinon filtrer les candidats en mémoire après le fetch, la liste est petite).

### Vue et liste
`SidebarItem.readLater`, entrée sous « Aujourd'hui » (icône `eyeglasses`, comme la liste de lecture de Safari), compteur = nombre d'articles dans la file. Liste : articles `isQueued` **ou sélectionnés**, triés par `readLaterAt` décroissant. Inclure la sélection garde la ligne de l'article qu'on lit jusqu'à ce qu'on en choisisse un autre ; le filtre « Non lus » n'est pas changé.

### Action
Un `ReadLaterButton(articles:)` à côté de `KeepButton` dans `ArticleMenuItems` (donc menu contextuel et menu Article, même ordre) et dans la barre d'outils du volet de lecture. Bascule : « Retirer de Lire plus tard » si tous sont dans la file, sinon « Lire plus tard ». Raccourci ⇧⌘D (liste de lecture de Safari), libre dans l'app.

### Sauvegarde
`ArticleEntry.readLaterAt: Date?` optionnel : les anciennes sauvegardes se décodent (nil) et la restauration recopie la date.

## Risks / Trade-offs

- [Article remis en non lu par erreur revient dans la file] → voulu, et « Retirer de Lire plus tard » reste à un raccourci.
- [`readLaterAt` reste posé sur des articles lus] → sans effet visible ; il est purgé avec l'article. Pas de nettoyage.
- [Prédicat avec optionnel refusé par SwiftData à l'exécution] → test de purge dans `LibraryTests` ; repli en filtrage mémoire.
