# Proposal

## Why

Les podcasts sont des flux RSS dont chaque épisode joint un fichier audio. Cairn les importe, mais n'en montre que le texte : impossible d'écouter l'épisode sans passer par une autre app.

## What Changes

- À l'import, Cairn retient le fichier audio joint à un article (RSS `enclosure`, lien Atom `rel="enclosure"`, pièce jointe JSON Feed), quand son type est audio ou, sans type, quand son extension l'est.
- Un article avec un audio affiche, sous son en-tête, le lecteur du système (lecture, position, volume). La lecture s'arrête quand on change d'article.
- Un épisode sans identifiant ni lien est reconnu par l'adresse de son audio.
- L'adresse de l'audio fait partie de la sauvegarde.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : écouter l'épisode d'un podcast.

## Impact

- `CairnCore` : `ParsedItem.audioURL`, `Article.audioURL` (optionnel, compatible CloudKit), lecture des trois formats, `Backup.ArticleEntry.audioURL` ; tests.
- Nouveau `App/EpisodePlayer.swift` (`AVPlayerView`), `App/ArticleDetailView.swift`.
