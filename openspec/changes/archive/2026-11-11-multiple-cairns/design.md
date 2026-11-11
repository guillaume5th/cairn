# Design

## Context

Voir proposal.md - Why. Aujourd'hui, un article gardé se reconnaît à `Article.isKept` (avec `keptAt`), utilisé par la purge, les listes et la barre latérale. `SidebarItem` a un cas `.cairn` unique et un cas `.tag(String)` (clé du tag) ; `SelectionMemory` est indexée par `SidebarItem` et enregistrée en JSON dans UserDefaults. Les dossiers d'abonnements ont déjà introduit un modèle nommé à clé unique (`Folder`), une alerte de saisie de nom et le contournement de la sélection voisine à la suppression. Le schéma doit rester compatible CloudKit.

## Goals / Non-Goals

**Goals :** plusieurs cairns nommés, un cairn par article gardé, déplacement entre cairns, vue et tags par cairn, reprise sans perte des articles déjà gardés.

**Non-Goals :** vue « tous les cairns » regroupée ; ordre manuel des cairns (triés par nom) ; icône ou couleur par cairn ; compteur de non-lus sur les cairns (il n'y en a pas aujourd'hui).

## Decisions

- **Modèle.** Nouveau `@Model Cairn { name, key, articles: [Article]? }` avec `@Relationship(deleteRule: .nullify, inverse: \Article.cairn)`, et `Article.cairn: Cairn?`. `isKept` est conservé : la purge et les listes s'en servent, et le changer casserait la compatibilité avec une base synchronisée. `Library` maintient l'invariant `isKept == (cairn != nil)`. Alternative : déduire `isKept` de `cairn` — écartée, un prédicat sur relation optionnelle est moins sûr dans `#Predicate` et la purge en dépend.
- **API de `Library`.** `keep(_:in:now:)` (range dans le cairn et horodate `keptAt` ; pour un article déjà gardé, c'est un déplacement qui garde `keptAt`, la note et les tags), `unkeep(_:)` (remplace `setKept(false, _)` et vide aussi `cairn`), `createCairn(named:)`, `rename(_ cairn:, to:)`, `delete(_ cairn:)` (lève `CairnError.lastCairn` s'il est le dernier ; sinon retire ses articles via `setKept(false)` puis le supprime), `ensureCairn(context:)` (crée « Cairn » s'il n'y en a aucun, range tout article gardé sans cairn dans le premier par nom). La vérification de nom (vide, doublon par clé) est partagée entre dossiers et cairns : elle compare les clés en mémoire, il y a peu de dossiers et de cairns.
- **Lancement.** `AppState.launch` appelle `ensureCairn` avant la purge, puis enregistre. Cela couvre la mise à jour d'une base existante et les articles gardés arrivés par synchronisation sans cairn.
- **Sélection.** `SidebarItem.cairn(PersistentIdentifier)` et `.tag(PersistentIdentifier, String)` (cairn, clé du tag). L'ancienne mémoire enregistrée ne se décode plus : `SelectionMemory.load()` retombe alors sur ses valeurs par défaut (« Tous les articles »), une seule fois. La canonicalisation de `onAppear` traite les nouveaux identifiants et ramène un cairn ou un tag disparu sur `.all`.
- **Barre latérale.** Une section « Cairns » entre « Tous les articles » et « Abonnements », avec un « + » (« Nouveau cairn… ») aligné comme celui des abonnements. Chaque cairn (icône cairn, nom) est suivi de ses tags en retrait, comme aujourd'hui. Menu contextuel du cairn : « Renommer… », « Supprimer le cairn… » (désactivé s'il est le dernier), avec une confirmation indiquant le nombre d'articles. L'alerte de saisie de nom est généralisée aux dossiers et aux cairns.
- **Garder.** `KeepButton` reçoit la liste des cairns. Un seul cairn : comportement actuel (bouton bascule). Plusieurs cairns : un `Menu` listant les cairns, le cairn actuel coché (choisir un autre cairn déplace l'article), puis « Retirer du cairn » si l'article est gardé. Le même contenu sert dans le menu contextuel sous « Garder dans ». Le retrait garde sa confirmation quand il y a une note ou des tags.

## Risks / Trade-offs

- [Mise à jour d'une base existante] → `ensureCairn` est idempotent et ne fait que ranger ; vérifié en lançant l'app sur la base actuelle : tous les articles gardés, leurs notes et leurs tags sont dans « Cairn ».
- [Deux appareils créent chacun le cairn « Cairn » avant de se synchroniser] → deux cairns du même nom peuvent apparaître ; accepté, l'utilisateur en renomme ou en supprime un (même compromis que les dossiers et les tags).
- [La sélection mémorisée est perdue une fois à la mise à jour] → accepté : l'app s'ouvre sur « Tous les articles ».

## Migration Plan

Ajouts avec valeurs par défaut, pris en charge par la migration légère de SwiftData ; `ensureCairn` range les articles déjà gardés au premier lancement. Pas de retour arrière vers une version antérieure sur la même base, comme pour les changements de schéma précédents.
