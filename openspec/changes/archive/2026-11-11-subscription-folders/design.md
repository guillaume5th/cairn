# Design

## Context

Voir proposal.md - Why. Aujourd'hui, `Feed` n'a aucun regroupement ; `OPML.parse` renvoie une liste plate de `[OPMLFeed]` et `OPML.export` écrit des outlines à plat. La barre latérale liste les abonnements triés par titre dans une seule `Section`, et `SidebarItem` (`all`, `cairn`, `tag(String)`, `feed(PersistentIdentifier)`) détermine la liste d'articles et la `SelectionMemory` de chaque entrée. Le schéma doit rester compatible CloudKit : valeur par défaut sur chaque propriété, relations optionnelles, pas de `.unique`.

## Goals / Non-Goals

**Goals :** un seul niveau de dossiers, la vue d'un dossier comme liste d'articles, l'aller-retour OPML avec les dossiers.

**Non-Goals :** dossiers imbriqués ; ordre manuel des dossiers ou des abonnements (les deux restent triés par nom) ; choix d'un dossier dans la fenêtre « Ajouter un abonnement » (on le range ensuite) ; glisser plusieurs abonnements à la fois.

## Decisions

- **Modèle.** Nouveau `@Model Folder { name, key, feeds: [Feed]? }` avec `@Relationship(deleteRule: .nullify, inverse: \Feed.folder)`, et `Feed.folder: Folder?`. La règle nullify donne gratuitement « la suppression remet les abonnements à la racine ». `key` réutilise `Library.tagKey` (insensible à la casse et aux accents), la même règle d'identité que les tags ; l'unicité est donc garantie dans `Library`, comme pour les tags et les abonnements. Alternative : un `folderName: String` sur `Feed` — écartée, car renommer toucherait chaque abonnement et un dossier vide ne pourrait pas exister.
- **API de `Library`.** `createFolder(named:)`, `rename(_:to:)` (les deux lèvent `CairnError.duplicateFolder` / refusent un nom vide), `move(_ feed:, to: Folder?)`, `delete(_ folder:)`. Testées dans `CairnCore`.
- **OPML.** `OPMLFeed` gagne `folder: String?`. Le parseur garde une pile des outlines ouverts sans `xmlUrl` ; un flux prend le titre du premier (le plus externe), si bien que les sous-dossiers sont fusionnés dans leur dossier de premier niveau. Les dossiers sans flux sont ignorés. L'export regroupe les flux sous un `<outline text="…">` par dossier (triés par nom), les flux sans dossier à la racine. `importOPML` retrouve les dossiers par clé, crée ceux qui manquent, et ne range que les abonnements nouvellement ajoutés.
- **Barre latérale.** Dans la `Section` Abonnements : un `DisclosureGroup` par dossier (libellé = nom du dossier, icône dossier, badge = somme des `unreadCount` de ses abonnements, tag `.folder(id)`, menu contextuel Renommer… / Supprimer le dossier), puis les abonnements à la racine. La ligne d'abonnement est factorisée en une seule vue réutilisée aux deux endroits. Le « + » de l'en-tête devient un `Menu` avec « Ajouter un abonnement… » (⌘N inchangé) et « Nouveau dossier… ». La saisie du nom, à la création comme au renommage, passe par une `.alert` avec un `TextField` ; un doublon affiche l'alerte existante `state.message`.
- **Glisser-déposer.** Les lignes d'abonnement sont `.draggable(feed.url)` (un `String` est déjà `Transferable` ; l'URL identifie un abonnement de façon unique) ; les lignes de dossier reçoivent un `.dropDestination(for: String.self)`, et l'en-tête de section aussi pour « Aucun dossier ». Le menu contextuel « Déplacer vers » est le chemin clavier et accessible, et le recours si le glisser-déposer dans une `List` sélectionnable se comporte mal.
- **Dépliage des dossiers.** Dépliés par défaut ; les clés des dossiers repliés sont stockées dans `@AppStorage` (sur ce Mac, comme la sélection). Au renommage, l'état replié suit la nouvelle clé.
- **Liste d'articles.** `SidebarItem.folder(PersistentIdentifier)` ; `visibleArticles` filtre les `articles` dont `feed?.folder?.persistentModelID == id`. Titre = nom du dossier. `SelectionMemory` est déjà indexée par `SidebarItem`, donc la mémoire fonctionne dès que la canonicalisation de `onAppear` traite aussi les identifiants `.folder` et ramène un dossier disparu sur `.all`. Quand le dossier affiché est supprimé, la sélection revient sur `.all` une fois la ligne retirée, car la `List` déplace sinon sa sélection sur la ligne voisine.

## Risks / Trade-offs

- [Ajout d'un modèle et d'une relation à une base existante au format CloudKit] → les deux sont des ajouts avec valeurs par défaut, que la migration légère de SwiftData prend en charge ; vérifié en lançant l'app sur la base existante : tous les abonnements et articles sont toujours là.
- [Le glisser-déposer dans une `List(selection:)` sur macOS peut entrer en conflit avec la sélection des lignes] → vérifié dans l'app ; « Déplacer vers » couvre le même besoin dans tous les cas.
- [Deux appareils créent le même nom de dossier avant synchronisation] → des doublons par clé peuvent apparaître après la synchronisation CloudKit ; accepté, l'utilisateur peut en renommer ou en supprimer un (même compromis que pour les tags).

## Migration Plan

Aucune migration de données : les abonnements existants ont `folder == nil` et s'affichent à la racine. Retour arrière = revert ; une version antérieure ne doit pas rouvrir la base migrée, donc la mise à jour reste sans retour, comme les changements de schéma précédents.
