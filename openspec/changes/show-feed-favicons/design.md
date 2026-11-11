# Design

## Context

- `FeedParser` ne lit aujourd'hui que le titre du flux et ses items ; FeedKit expose pourtant les champs utiles : Atom `icon`, JSON Feed `favicon`, `icon` et `home_page_url`, RSS/RDF `channel.link` (lien du site). Atom n'a pas de lien de site direct : le lien `alternate` du flux en tient lieu.
- `FeedFetcher` télécharge et parse les flux en parallèle (6 à la fois) ; `Library.refreshAll` applique les résultats sur le contexte principal. Les articles sont ingérés sans jamais être modifiés ensuite.
- Le schéma SwiftData doit rester compatible CloudKit : propriétés optionnelles ou avec valeur par défaut, pas de `.unique`.
- L'app est sandboxée avec `network.client` : les requêtes vers les sites sont déjà autorisées.
- Un article garde `sourceTitle` pour survivre à la suppression de son abonnement (`Library.delete(_ feed:)` supprime les non gardés et laisse `nullify` détacher les gardés).

## Goals / Non-Goals

**Goals:**
- Une recherche d'icône testable sans réseau, avec le `StubProtocol` existant.
- Aucune requête d'icône sur le chemin critique de l'affichage des articles.

**Non-Goals:**
- Choisir la « meilleure » icône parmi plusieurs tailles déclarées : on prend la première déclarée.
- Icône par article (seule la source compte).
- Retour visuel pendant la recherche (l'icône générique en tient lieu).
- Réglage de la fréquence de revérification.

## Decisions

### Ordre de recherche : flux, page d'accueil, `/favicon.ico`
1. **Flux** : Atom `icon`, JSON Feed `favicon` puis `icon`. On ignore volontairement RSS `<image>` et Atom `logo` : ce sont des logos souvent larges et rectangulaires, illisibles à 16 pt.
2. **Page d'accueil** : URL du site = lien de site du flux (RSS `channel.link`, Atom `alternate`, JSON `home_page_url`), sinon l'origine de l'URL du flux. On y cherche le premier `<link rel>` contenant le jeton `icon` (`icon`, `shortcut icon`, `apple-touch-icon`) et on résout son `href` par rapport à l'URL finale de la page (après redirections).
3. **Conventionnel** : `/favicon.ico` à l'origine du site.

Chaque candidat n'est retenu que si les données se décodent en image (`NSImage(data:)`, qui lit PNG, ICO, GIF, JPEG et SVG). Sinon on passe au suivant.

- Alternative écartée : un service tiers de favicons (Google, DuckDuckGo). Plus simple et plus fiable, mais il révèle la liste des abonnements à un tiers.
- Alternative écartée : uniquement `/favicon.ico`. Beaucoup de sites récents ne servent leur icône qu'au chemin déclaré dans leur HTML.

### Lecture du HTML par expression régulière bornée
Pas de parseur HTML dans le projet, et en ajouter un pour une seule balise ne vaut pas une dépendance. On lit au plus les 256 Ko premiers octets de la page, on s'arrête à `</head>` et on extrait les balises `<link …>` par expression régulière, insensible à la casse et à l'ordre des attributs.
- `shortcut: pas de vrai parseur HTML, balises <link> mal formées ou générées en JavaScript ignorées ; passer à un parseur si des sites courants échouent.` Ce commentaire ira dans le code.

### Stockage : données de l'icône sur le `Feed`, en stockage externe
- `Feed.iconData: Data?` avec `@Attribute(.externalStorage)` (compatible CloudKit, gardé hors de la ligne SQLite).
- `Feed.iconCheckedAt: Date?` : date de la dernière recherche, réussie ou non.
- `Article.sourceIconData: Data?` (stockage externe) : rempli uniquement par `Library.delete(_ feed:)` sur les articles gardés, juste avant de supprimer l'abonnement. Pas de copie à l'ingestion : elle dupliquerait l'icône sur chaque article alors que seuls les orphelins en ont besoin.
- L'affichage lit `article.feed?.iconData ?? article.sourceIconData`.
- Taille maximale acceptée : 512 Ko. Au-delà, le candidat est ignoré (protection contre une « icône » qui serait un gros fichier).
- Alternative écartée : un cache de fichiers dans `Caches/`. Le système peut le purger à tout moment, il faudrait le resynchroniser avec la base, et il ne suivrait pas une future synchronisation CloudKit.

### Déclenchement : après le rafraîchissement, au plus tous les 7 jours
- `Library.refreshIcons(context:fetcher:now:)` sélectionne les abonnements dont `iconCheckedAt` est nul ou date de plus de 7 jours, lance les recherches en parallèle (même limite de 6 que les flux) et applique les résultats sur le contexte principal : `iconData` n'est remplacé que par une nouvelle icône trouvée, `iconCheckedAt` est mis à jour dans tous les cas.
- Appelé à la fin de `AppState.refresh()`, une fois les articles ingérés et enregistrés, et après l'ajout d'un abonnement. L'indicateur de rafraîchissement couvre aussi cette étape. La règle des 7 jours la rend rare.
- Les champs d'icône déclarés par le flux sont connus au moment du parse : `ParsedFeed` gagne `siteURL` et `iconURL`, transmis à la recherche pour éviter un second téléchargement du flux. L'ingestion les recopie sur le `Feed` dans deux propriétés `@Transient` (`siteURLHint`, `iconURLHint`) : en mémoire seulement, elles ne touchent pas au schéma et `refreshIcons` les relit sur les mêmes objets du contexte principal sans changer de signature. Pour les abonnements qui ne sont pas rafraîchis avec succès dans la session (flux en erreur), la recherche part de l'origine de l'URL du flux.
  - Alternative écartée : enregistrer ces URL dans la base. Deux colonnes de plus pour une information qui se relit à chaque rafraîchissement.
- Un intervalle unique de 7 jours, que la recherche ait abouti ou non : il espace les nouvelles tentatives après un échec et suit les changements d'icône, sans deux règles à maintenir.

### Affichage : une vue `SourceIcon` partagée
- Une seule vue SwiftUI dans `App` prend des `Data?` et affiche l'image redimensionnée (`resizable`, `scaledToFit`), ou le symbole générique `dot.radiowaves.up.forward` si les données sont absentes ou illisibles. Les deux sont posés en surimpression d'un symbole `square` masqué, qui fixe le cadre : l'icône prend ainsi la taille et la ligne de base qu'aurait un symbole dans le texte courant, y compris le réglage de taille des icônes de la barre latérale.
  - Alternative écartée : `@ScaledMetric`, qui ne suit pas la taille du texte sur macOS ; et un calcul à partir de `NSFont`, qui ignorerait le réglage de la barre latérale.
- Le décodage `NSImage(data:)` étant coûteux dans une liste, l'image décodée est mise en cache en mémoire par identité de données (`NSCache` clé = hash des données). `shortcut: cache sans éviction fine ; à revoir si la mémoire devient un sujet avec des centaines d'abonnements.`
- Emplacements : ligne d'abonnement de `SidebarView`, ligne de `ArticleListView` (avant `sourceTitle`, après le badge du cairn), en-tête de `ArticleDetailView`.

## Risks / Trade-offs

- [Contenu hostile servi comme icône] → Taille plafonnée à 512 Ko, décodage par `NSImage` uniquement, aucune exécution ; les SVG sont rendus par AppKit comme image statique.
- [Page d'accueil lourde ou lente] → Lecture limitée à 256 Ko, délai de 20 s comme pour les flux, échec silencieux.
- [Icône déclarée en HTML générée côté client] → Non trouvée ; repli sur `/favicon.ico`, puis icône générique.
- [Requêtes supplémentaires vers les sites] → Au plus deux à trois par abonnement tous les 7 jours, vers des sites déjà contactés pour leurs flux.
- [Migration du schéma] → Propriétés optionnelles uniquement : migration légère automatique de SwiftData, aucune donnée existante touchée.

## Migration Plan

Aucune étape manuelle : la migration légère s'applique au premier lancement, puis le premier rafraîchissement recherche l'icône de tous les abonnements (aucun n'a encore de `iconCheckedAt`). Retour arrière : une version antérieure ne sait pas ouvrir la base migrée ; acceptable pour une app locale non distribuée, sinon repartir d'une base vide et réimporter l'OPML.
