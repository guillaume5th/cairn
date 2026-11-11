# Design

## Context

Projet vierge (voir proposal.md - Why). Contraintes qui pèsent sur l'approche :

- Écosystème Apple uniquement : macOS d'abord, iOS/iPadOS ensuite → le code métier doit être partageable.
- Sync iCloud hors V1, mais à ne pas rendre impossible.
- La machine de dev n'a que les Command Line Tools (Swift 6.4) : pas de Xcode, pas d'`xcodebuild`. Une app SwiftUI signée, sandboxée et lançable demande Xcode.
- Données 100 % locales, un seul utilisateur, volume modeste (quelques centaines d'abonnements, quelques milliers d'articles gardés).

## Goals / Non-Goals

**Goals:**

- Un module cœur sans UI, testable en ligne de commande, qui contient modèles, parsing, OPML, ingestion, purge et recherche.
- Une app SwiftUI fine qui ne fait qu'afficher et déclencher.
- Un schéma de données compatible avec une future sync CloudKit.

**Non-Goals:**

- Abstraction de stockage ou de réseau « pour plus tard » (pas de protocoles Repository/Service sans second implémenteur).
- Recherche indexée (FTS).
- Distribution (notarisation, Mac App Store, mises à jour automatiques).

## Decisions

### Structure : package `CairnCore` + projet XcodeGen

```
cairn/
  project.yml              # XcodeGen -> Cairn.xcodeproj (non versionné)
  App/                     # cible app SwiftUI (vues, commandes, entitlements)
  CairnCore/               # Swift package local
    Package.swift          # dépend de FeedKit
    Sources/CairnCore/     # modèles SwiftData, FeedFetcher, OPML, Retention, Search
    Tests/CairnCoreTests/  # Swift Testing + fixtures RSS/Atom/OPML
```

- `swift test` dans `CairnCore/` couvre toute la logique ; l'app ne contient que des vues.
- XcodeGen garde un `project.yml` lisible et diffable au lieu d'un `.pbxproj`. Alternatives écartées : projet Xcode créé à la main (pbxproj illisible en revue) ; exécutable SwiftPM seul (pas de bundle, sandbox ni entitlements, donc pas une vraie app).
- Le package est réutilisable tel quel par une future cible iOS.

### Persistance : SwiftData, schéma compatible CloudKit

Modèles (dans `CairnCore`) :

```
Feed     : url, title, lastError?, articles -> [Article] (relation, delete rule nullify)
Article  : externalID, link, title, publishedAt, content?, isRead, isKept, keptAt?,
           note, sourceTitle, feed? , tags -> [Tag]
Tag      : name (affiché), key (minuscule, sans accent), articles -> [Article]
```

- Pas de `@Attribute(.unique)` ni de relation obligatoire : CloudKit les interdit. L'unicité (flux par URL, article par `externalID` dans un flux, tag par `key`) est garantie dans le code d'ingestion, et c'est testé.
- `sourceTitle` est dupliqué sur l'article pour qu'un article gardé garde sa source après la suppression de l'abonnement. Supprimer un abonnement : on supprime explicitement ses articles non gardés, et la relation `nullify` détache les articles gardés.
- Alternative écartée : GRDB + SQLite FTS5 (meilleure recherche, mais sync CloudKit à écrire soi-même).

### Récupération : FeedKit + URLSession, fetch parallèle, écriture sur le contexte principal

- `FeedFetcher` télécharge chaque flux avec `URLSession` et le parse avec `Feed(data:)` de FeedKit (RSS, RDF, Atom, JSON Feed), dans un `TaskGroup` limité à 6 requêtes simultanées. Il renvoie des valeurs simples (`ParsedFeed`, `ParsedItem`) ou une erreur par flux.
- Les requêtes ignorent le cache HTTP local (`reloadIgnoringLocalCacheData`) : sans `Cache-Control`, URLSession applique une fraîcheur heuristique et un ⌘R pouvait renvoyer une copie périmée sans contacter le serveur. Les flux sont petits, le retéléchargement complet est acceptable.
- L'ingestion (dédoublonnage, insertion, `lastError`) est une fonction du cœur appliquée sur le `ModelContext` principal. Elle est simple, testable avec un conteneur en mémoire, et le volume par rafraîchissement (quelques centaines d'items) ne justifie pas un `@ModelActor`.
- Clé de dédoublonnage : `guid`/`id` du flux, à défaut le lien. Les articles existants ne sont jamais modifiés, ce qui préserve lu/gardé/note/tags.
- Un drapeau `isRefreshing` côté app ignore un ⌘R pendant un rafraîchissement.
- L'app sauvegarde explicitement le contexte après chaque opération qui insère des objets (ajout, rafraîchissement, import). Un modèle n'obtient son `persistentModelID` définitif qu'à la sauvegarde, et une `List` qui a mémorisé l'identifiant temporaire ne retrouve plus la sélection. Le reste des modifications (lu, note, tags) passe par l'autosave.
- L'app garde son `ModelContainer` pour toute sa durée de vie : un `ModelContext` ne retient pas son conteneur.

### OPML : parseur et générateur maison sur `XMLParser`

FeedKit ne gère pas l'OPML. Le format est trivial : on parcourt récursivement les `<outline>` portant un `xmlUrl` (les dossiers sont aplatis), et on écrit un OPML 2.0 avec `text`, `title`, `type="rss"`, `xmlUrl`. Import et export passent par `fileImporter`/`fileExporter` de SwiftUI.

### Lecture : rendu HTML du flux dans un `WebView` SwiftUI verrouillé

Le contenu des flux est du HTML. On l'affiche dans un `WebView` SwiftUI (WebKit, macOS 26+) piloté par un `WebPage` qui charge une chaîne HTML locale (pas la page web), avec :

- JavaScript désactivé (`defaultNavigationPreferences.allowsContentJavaScript = false`), magasin de données non persistant ;
- un CSP `default-src 'none'; img-src https: data:; style-src 'unsafe-inline'` : seules les images distantes passent ;
- tout clic sur un lien annulé et ouvert dans le navigateur par défaut (`NSWorkspace.open`) par un `WebPage.NavigationDeciding`.

Alternative écartée : `NSAttributedString(html:)` (lent, sur le thread principal, rendu pauvre). Ce n'est pas la « WebView intégrée » exclue du périmètre : on n'affiche jamais la page d'origine.

### Recherche : filtrage en mémoire des articles gardés

On charge les articles gardés et on filtre en Swift avec `localizedStandardContains` (insensible à la casse et aux accents) sur titre, contenu, note et noms de tags. Un `#Predicate` ne traverse pas bien la relation vers les tags.
shortcut: recherche linéaire en mémoire, à remplacer par un index si le cairn dépasse ~10 000 articles ou si la frappe devient lente.

### Rétention : 30 jours, constante unique

`Retention.days = 30` dans le cœur sert à deux endroits : la purge au lancement (articles non gardés publiés avant la limite) et le filtre d'ingestion (on n'importe pas un article déjà plus vieux que la limite, sinon il réapparaîtrait à chaque rafraîchissement). Pas de réglage utilisateur en V1.

### UI : `NavigationSplitView` à 3 colonnes

```
+----------------+------------------------+-----------------------------+
| Tous articles  | [x] Non lus            | Titre                       |
| Cairn          |                        | Source - date   [Garder]    |
|  - tag swift   | * Titre article  date  | --------------------------- |
|  - tag k8s     |   Titre article  date  | contenu HTML du flux         |
| ----------     |                        |                             |
| Abonnement (3) |                        | Note / Tags (si gardé)      |
| Abonnement !   |                        | [Ouvrir dans le navigateur] |
+----------------+------------------------+-----------------------------+
 Fichier : Ajouter un flux, Importer OPML, Exporter OPML ; Affichage : ⌘R
```

La recherche passe par `.searchable` sur la vue Cairn. Les commandes sont dans le menu de l'app via `.commands`.

shortcut: la `List` d'articles est reconstruite (`.id(articles.count)`) quand des articles arrivent, car macOS garde une hauteur de ligne périmée (ligne tronquée) pour les lignes insérées pendant l'affichage. Prix : retour en haut de liste et perte du focus clavier à chaque rafraîchissement qui ajoute des articles. À retirer quand SwiftUI corrige le problème. `scrollPosition` (macOS 15) a été essayé pour restaurer la position : il n'a aucun effet sur une `List` (seulement sur `ScrollView`).

⌘F (menu Édition) bascule sur la vue Cairn si besoin et place le focus dans le champ de recherche (`.searchFocused`).

### Sandbox et réglages de build

- App Sandbox avec `com.apple.security.network.client` et `com.apple.security.files.user-selected.read-write` (OPML).
- Cible la dernière version de macOS (27.0), Swift 6 en mode de langage 6, swift-tools 6.4 ; FeedKit au plancher de sa dernière version (10.10.2). Dependabot propose chaque semaine les nouvelles versions des dépendances ; la cible macOS est remontée à la main à chaque nouvelle version majeure.

## Risks / Trade-offs

- [Xcode absent de la machine] → Installer Xcode est la première tâche, et rien d'autre ne peut se construire avant. XcodeGen s'installe via Homebrew.
- [Concurrence stricte de Swift 6 et SwiftData : erreurs de `Sendable` entre fetch et contexte] → Le fetcher ne renvoie que des structs `Sendable`, et seul le contexte principal touche aux modèles. En cas de blocage, on repasse la cible app en mode de langage 5, sans toucher au design.
- [Flux mal formés ou exotiques que FeedKit rejette] → Erreur isolée par flux (spec feed-fetching). On ajoute une fixture de test à chaque cas réel rencontré.
- [Variantes d'OPML selon les lecteurs (Feedly, NetNewsWire, Inoreader)] → Le parseur ne dépend que de `xmlUrl` et ignore le reste. Fixtures issues de plusieurs lecteurs.
- [Pas de contrainte d'unicité en base] → Le dédoublonnage dépend du code d'ingestion. Il est couvert par des tests de rafraîchissements successifs.
- [Recherche linéaire] → Acceptable pour le volume visé, voir le raccourci ci-dessus.
- [Contenu HTML hostile dans un flux] → Pas de JS, CSP restrictif, pas de navigation dans la vue.

## Migration Plan

Aucune : première version, pas de données existantes.
