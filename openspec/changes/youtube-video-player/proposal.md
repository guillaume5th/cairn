# Proposal

## Why

Depuis la correction de l'abonnement aux chaînes YouTube, leurs vidéos arrivent dans Cairn, mais un article YouTube n'a quasiment pas de contenu : il faut l'ouvrir dans le navigateur pour regarder la vidéo. Cairn sait déjà lire un épisode de podcast sous l'en-tête de l'article ; la vidéo mérite le même traitement.

## What Changes

- Un article dont le lien est une vidéo YouTube (`youtube.com/watch?v=ID`, `youtu.be/ID`) affiche, sous l'en-tête et au-dessus du contenu, un lecteur vidéo intégré (embed `youtube-nocookie.com`).
- Un bouton « Ouvrir sur YouTube » reste visible sous le lecteur : c'est la sortie quand YouTube refuse l'intégration d'une vidéo.
- Sans contenu dans le flux (le cas des flux YouTube), la vidéo remplit le panneau de lecture et le message « Aucun contenu » n'apparaît plus.
- La lecture s'arrête quand l'utilisateur change d'article.
- Le contenu de l'article lui-même reste inchangé : toujours sans script ni contenu distant autre que les images.

## Capabilities

### New Capabilities

### Modified Capabilities
- `article-reading`: ajout d'une exigence « Regarder une vidéo YouTube », à côté de « Écouter un épisode de podcast », et modification de « Afficher un article » : la vidéo tient lieu de contenu quand le flux n'en fournit pas, au lieu du message « Aucun contenu ».

## Impact

- `CairnCore` : une fonction pure qui extrait l'identifiant de la vidéo d'un lien d'article, avec ses tests.
- `App/` : un lecteur vidéo (nouvelle vue autour d'une `WebPage` avec JavaScript actif, limitée aux domaines YouTube) inséré dans `ArticleDetailView`, à la place où s'affiche `EpisodePlayer` pour l'audio.
- Aucune dépendance ajoutée, aucun changement du modèle de données ni du parseur de flux.
- Hors périmètre : Shorts, playlists, vimeo et autres plateformes, reprise à la position, vitesse de lecture.
