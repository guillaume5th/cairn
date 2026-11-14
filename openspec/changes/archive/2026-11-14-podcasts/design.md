# Design

## Context

`FeedParser` transforme le flux FeedKit en `ParsedItem` ; `Library.ingest` crée les `Article`. Le lecteur (`ArticleDetailView`) affiche un en-tête natif puis le contenu dans une `WebPage` sans JavaScript, dont la CSP n'autorise que les images. Voir proposal.md.

## Goals / Non-Goals

**Goals:** écouter un épisode dans Cairn, avec les contrôles du système.

**Non-Goals:** lecture en arrière-plan d'un article à l'autre, file d'attente, reprise à la dernière position, vitesse de lecture, téléchargement hors ligne, vidéo ; audio des flux protégés par mot de passe.

## Decisions

- **`AVPlayerView` (AVKit) en style `inline`, dans l'en-tête natif.** Les contrôles du système, sans toucher à la CSP de la page. Alternative écartée : une balise `<audio>` dans la page, qui imposait d'ouvrir la CSP aux médias.
- **Premier audio retenu** : type `audio/*`, ou sans type une extension audio courante (mp3, m4a, aac, ogg, opus, wav).
- **Identifiant d'un épisode : id, sinon lien, sinon adresse de l'audio**, pour ne pas écarter les épisodes sans lien.
- **La lecture s'arrête au changement d'article** : le lecteur appartient à la vue de l'article.

## Risks / Trade-offs

- [Articles déjà importés] → ils n'ont pas l'audio (l'import ne modifie jamais un article existant) ; les épisodes suivants l'ont.
