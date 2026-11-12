# Design

## Context

- `Library.addFeed(urlString:)` exige une URL http(s) avec hôte. Il vérifie qu'elle n'est pas déjà suivie, la télécharge avec `FeedFetcher.fetch` (qui parse directement), puis crée le `Feed`.
- `FeedIcon.declaredIcons(inHTML:baseURL:)` analyse déjà les balises `<link>` du `<head>` par expressions régulières, avec un helper `attribute(_:in:)`.
- `FeedParser.parse` lit RSS, RDF, Atom et JSON Feed, et lève une erreur sur du HTML.

## Goals / Non-Goals

**Goals:**
- Un seul téléchargement de la page saisie : on essaie d'abord de la parser comme un flux, puis on la lit comme du HTML.
- Une logique de découverte entièrement dans CairnCore, testable sans réseau.

**Non-Goals:**
- Chercher dans le corps de la page des liens « RSS » qui ne sont pas déclarés dans le `<head>`.
- Proposer des flux d'autres sites (agrégateurs, services de recherche de flux).

## Decisions

1. **`Library.discoverFeeds(urlString:fetcher:) async throws -> [DiscoveredFeed]`** (`url`, `title`), séparée de l'abonnement :
   1. Normaliser l'adresse : sans schéma, ajouter `https://`.
   2. Télécharger une fois. Si le contenu se parse comme un flux, renvoyer `[ce flux]`.
   3. Sinon, lire les `<link rel="alternate" type="application/rss+xml|atom+xml|feed+json">` du `<head>` (pas `application/json` seul : WordPress déclare ainsi son API REST), résolus contre l'URL finale (après redirections). Les doublons sont retirés et l'ordre du document est conservé.
   4. S'il n'y en a aucun, essayer les chemins usuels à l'origine du site, dans l'ordre, et garder ceux qui se parsent. On s'arrête au premier trouvé pour ne pas multiplier les requêtes.
   5. Si rien n'est trouvé, lever `CairnError.noFeedFound`.

   **Alternative écartée :** tout faire dans `addFeed`. Le choix entre plusieurs flux impose de revenir vers l'interface entre la découverte et l'abonnement.
2. **`addFeed` prend l'URL d'un flux déjà découvert.** Il garde ses vérifications : doublon avant et après le téléchargement, et titre du flux. `AppState.addFeed(_:)` appelle d'abord `discoverFeeds`. Avec un seul résultat, il ajoute le flux. Avec plusieurs, il publie `state.feedChoices` et l'interface affiche un `confirmationDialog` : un bouton par flux, avec titre et adresse. Les flux déjà suivis sont désactivés et marqués « déjà suivi ».
3. **Analyse des `<link>` mise en commun.** On extrait de `FeedIcon` un petit utilitaire `HTMLHead.links(in:baseURL:)`, qui renvoie `rel`, `type`, `href`, `title` et `sizes`. `declaredIcons` et la découverte de flux s'appuient dessus. On garde le raccourci des expressions régulières, avec la même mention « shortcut ».
4. **Le titre affiché pour un choix** est l'attribut `title` du `<link>`. À défaut, c'est l'adresse du flux. On ne télécharge pas chaque candidat juste pour lire son titre.

## Risks / Trade-offs

- **[Risque]** Certains sites ne déclarent leur flux que via JavaScript. → Les chemins usuels couvrent une partie de ces cas. Sinon, le message « aucun flux trouvé » invite à saisir l'URL du flux.
- **[Risque]** Essayer jusqu'à 6 chemins usuels ralentit l'ajout sur un site sans flux. → Les requêtes partent en parallèle (limite de 3), avec un délai de 10 s.
- **[Compromis]** Le `confirmationDialog` liste mal les très longues adresses. Le titre passe en premier et l'adresse est tronquée au milieu.
