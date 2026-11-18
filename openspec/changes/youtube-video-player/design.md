# Design

## Context

Le contenu d'un article est rendu par `HTMLView` dans une `WebPage` où le JavaScript est désactivé, avec une CSP `default-src 'none'` ; la spec « Afficher un article » exige de ne charger que des images. Un embed YouTube a besoin de JavaScript et d'un `iframe`, ce qui est incompatible avec cette page. `ArticleDetailView` affiche déjà, sous l'en-tête, un lecteur natif pour l'audio des podcasts (`EpisodePlayer`) au-dessus de la vue web : c'est le modèle à suivre. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Regarder une vidéo YouTube sans quitter Cairn, sans affaiblir l'isolation du contenu des flux.

**Non-Goals:**
- Détecter côté app l'erreur 150/153 de YouTube, gérer Shorts, playlists, ou d'autres plateformes.

## Decisions

- **Lecteur à part, pas d'iframe dans le contenu.** Une seconde `WebPage` (`VideoPlayer`), insérée comme `EpisodePlayer`, charge l'URL d'embed `https://www.youtube-nocookie.com/embed/<ID>`. Le contenu de l'article, la CSP et le test `dropsScriptsAndIframes` ne changent pas. Alternative écartée : injecter l'iframe dans le HTML de l'article, ce qui obligerait à activer JavaScript pour tout le contenu des flux et à ouvrir la CSP.
- **Extraction de l'identifiant dans CairnCore** : `Library.youtubeVideoID(in link: String?) -> String?`, fonction pure testable. Accepte `youtube.com`/`www.`/`m.` avec `/watch?v=ID` et `youtu.be/ID` ; l'identifiant doit correspondre à `[A-Za-z0-9_-]{11}`, ce qui évite d'injecter autre chose dans l'URL d'embed. Le reste (chaîne, playlist, Shorts) renvoie nil.
- **Isolation de la `WebPage` du lecteur** : JavaScript actif (nécessaire), magasin de données non persistant comme `HTMLView`, et un `NavigationDeciding` qui n'autorise que les hôtes `youtube-nocookie.com` et `youtube.com` ; tout lien cliqué s'ouvre dans le navigateur, tout le reste est annulé. Lecture inline autorisée, plein écran laissé au lecteur YouTube.
- **Arrêt à la sélection d'un autre article** : la vue est recréée par identifiant d'article (`.id(videoID)`), donc l'ancienne `WebPage` est détruite et la lecture s'arrête, comme `dismantleNSView` pour l'audio.
- **Repli sans détection** : l'erreur d'intégration se produit dans l'iframe de YouTube, hors de portée de l'app sans API IFrame. Un bouton « Ouvrir sur YouTube » est donc toujours affiché sous le lecteur, en plus du bouton « Ouvrir dans le navigateur » de la barre d'outils.
- **La vidéo tient lieu de contenu** : quand `Library.displayedContent` est nil et qu'il y a une vidéo, `ArticleDetailView` n'affiche pas `ContentUnavailableView` et le lecteur n'est plus plafonné en hauteur (il garde son ratio 16/9 sur la largeur du panneau). Avec un contenu, le plafond de 360 pt reste. `displayedContent` lui-même ne change pas : il alimente aussi les citations, la progression et le résumé, qui n'ont rien à lire dans une vidéo.
- **Pas de réglage** : « Ouvrir dans le navigateur » reste une action explicite de l'utilisateur et ne remplace pas le lecteur.

## Risks / Trade-offs

- [YouTube refuse l'embed sans référent (erreur 153), constaté dans Cairn Dev] → la requête de l'embed envoie `Referer: https://www.youtube-nocookie.com/`, ce qui corrige l'erreur. Repli si cela cesse de marcher : page HTML minimale avec `baseURL` `youtube-nocookie.com`.
- [JavaScript actif dans une vue web, avec du contenu tiers] → domaines limités par le décideur de navigation, magasin non persistant, aucun accès au contenu des flux.
- [Consommation et pistage] → `youtube-nocookie.com` et magasin non persistant ; le trafic vers YouTube n'a lieu que si l'utilisateur ouvre l'article.
- [Les articles ouverts automatiquement chargent le lecteur] → il ne démarre pas la lecture tant que l'utilisateur ne clique pas (pas d'autoplay).
