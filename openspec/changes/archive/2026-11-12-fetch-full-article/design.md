# Design

## Context

- `Article.content` contient le HTML fourni par le flux. `HTMLView` l'affiche avec WebKit (`WebPage`), sans JavaScript ; seules les images distantes sont chargées, et les liens s'ouvrent dans le navigateur.
- `Library.isExcerpt` juge qu'un contenu est un extrait s'il fait moins de 500 caractères de texte. `articleSummaryPrompt` et `digestPrompt` lisent `content`.
- `FeedIconFetcher.download` sait déjà télécharger une page en HTTP(S), avec une limite de taille.
- Le schéma SwiftData est compatible CloudKit : chaque propriété a une valeur par défaut ou est optionnelle.

## Goals / Non-Goals

**Goals:**
- Une extraction fiable sur la plupart des sites d'actualité et des blogs, sans écrire d'heuristique maison.
- Le même rendu et les mêmes protections que le contenu du flux.

**Non-Goals:**
- Les pages derrière connexion ou paywall : on ne transmet ni cookies ni identifiants.
- Les articles sur plusieurs pages, ou les sites qui affichent leur contenu uniquement par JavaScript.
- Charger d'office le texte intégral de tous les articles : c'est opt-in, par abonnement.

## Decisions

1. **Extraction avec Readability.js de Mozilla, embarqué dans l'app et exécuté dans un `WebPage` invisible.**
   - La page est chargée comme une chaîne HTML (`load(html:baseURL:)`), avec le JavaScript de la page désactivé (`allowsContentJavaScript = false`). Notre script tourne alors dans un monde isolé (`callJavaScript(_:contentWorld:)`) : `new Readability(document).parse()`. Il en ressort `content` (HTML nettoyé), `title` et `length`.
   - **Pourquoi :** c'est l'algorithme du mode Lecture de Firefox. Il est éprouvé, sous licence Apache 2.0, et WebKit est déjà utilisé par l'app.
   - **Alternative écartée :** une heuristique en Swift par expressions régulières (comme `FeedIcon.declaredIcons`). Elle est fragile sur du HTML réel.
   - **Alternative écartée :** SwiftSoup, plus un portage de Readability. C'est une dépendance de plus, et un portage à maintenir.
2. **Téléchargement sans cookies.**
   - Il passe par une `URLSession` éphémère (`.ephemeral`, sans cookies), avec un `User-Agent` de navigateur générique, une limite de 5 Mo et un délai de 20 s.
   - Le HTML obtenu est passé à `WebPage`. WebKit ne fait donc aucune requête de navigation vers le site ; il ne charge que les images au rendu.
3. **Le résultat est lui aussi passé par `HTMLView`.** Les mêmes règles s'appliquent : pas de script, liens vers le navigateur. Le HTML issu de Readability est stocké tel quel ; on ne le réinterprète pas.
4. **Modèle de données :**
   - `Article.fullContent: String?` et `Article.fullContentFetchedAt: Date?` ;
   - `Feed.loadsFullContentSince: Date?`, la date d'activation de l'option (nil quand elle est désactivée), pour ne charger que les articles arrivés après ;
   - un état d'affichage `Article.showsFeedContent: Bool = false`, pour revenir au contenu du flux et le retenir d'une consultation à l'autre.

   Toutes ces propriétés ont une valeur par défaut. La migration SwiftData est légère, et la purge supprime le texte intégral avec l'article.
5. **Choix du contenu utilisé.**
   - Une fonction `Library.readableContent(_:)` renvoie le texte intégral s'il existe, sinon le contenu du flux.
   - Elle sert à l'affichage (sauf si l'utilisateur a choisi le contenu du flux), au prompt de résumé d'article, et à l'extrait de 200 caractères du résumé quotidien.
   - `isExcerpt` reste calculé sur le contenu effectivement résumé.
6. **Chargement automatique :**
   - Après `refreshAll`, on charge le texte intégral des articles des abonnements en mode automatique publiés depuis l'activation et jamais tentés (`fullContentFetchedAt` nil). Une tentative, réussie ou non, renseigne `fullContentFetchedAt`.
   - Au plus 3 chargements à la fois, en tâche séparée qui ne retarde pas la fin du rafraîchissement.
   - Un échec reste silencieux, et il n'y a pas de nouvelle tentative automatique.

## Risks / Trade-offs

- **[Risque]** Readability n'extrait rien sur les pages rendues côté client. → Le message « aucun contenu principal » s'affiche, et le contenu du flux reste visible.
- **[Risque]** Certains sites bloquent les clients qui ne sont pas des navigateurs (403). → On le traite comme un échec ordinaire, et l'utilisateur peut ouvrir l'article dans le navigateur.
- **[Risque]** Le texte intégral des abonnements en mode automatique fait grossir la base. → C'est opt-in, et la purge de 30 jours s'applique déjà aux articles non gardés.
- **[Compromis]** Le script embarqué (~90 Ko) est à mettre à jour de temps en temps. Sa version est épinglée dans le dépôt, avec sa licence.

## Migration Plan

- Nouvelles propriétés optionnelles : migration automatique, sans étape manuelle.
- Retour arrière : les colonnes ajoutées sont ignorées par une version précédente.
