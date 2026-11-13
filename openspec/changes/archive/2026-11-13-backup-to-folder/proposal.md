# Proposal

## Why

Tout ce que l'utilisateur a construit dans Cairn vit dans une seule base locale : ses abonnements classés en dossiers, ses cairns d'articles gardés avec leurs notes et étiquettes, ses réglages. Un disque qui lâche, une base corrompue ou une mauvaise manipulation, et tout est perdu : l'export OPML est manuel et ne couvre que les abonnements. Il faut une sauvegarde automatique, hors de la base, qu'on puisse réimporter.

## What Changes

- Sauvegarde automatique, une fois par jour, dans un fichier JSON écrit dans un dossier choisi une fois dans les Réglages, par exemple un dossier Cairn dans iCloud Drive.
- La sauvegarde contient les abonnements (titre, adresse, dossier, icône, option « Toujours charger les articles complets »), les dossiers, les cairns, tous les articles avec leur état lu (et pour les gardés leur cairn, note et étiquettes ; résumé et texte complet pour tous) et les réglages de l'app.
- Elle ne contient pas les résumés quotidiens ni l'état de l'interface (sélection, dernière tentative de résumé).
- Les 7 sauvegardes les plus récentes sont gardées dans le dossier ; les plus anciennes sont supprimées.
- Nouvelle section « Sauvegarde » dans les Réglages : dossier choisi, date de la dernière sauvegarde ou erreur, « Sauvegarder maintenant », « Restaurer… ».
- Restaurer une sauvegarde remplace, après confirmation, abonnements, dossiers, cairns, articles et réglages par ceux du fichier, chaque article retrouvant son état lu, puis rafraîchit les flux.
- Sans dossier choisi, rien n'est sauvegardé automatiquement (comportement actuel).

## Capabilities

### New Capabilities

- `backup` : sauvegarde automatique dans un dossier choisi, conservation des copies, restauration.

### Modified Capabilities

Aucune.

## Impact

- `CairnCore` : format de sauvegarde (structures `Codable`), création à partir de la base et restauration dans la base, avec tests.
- `App/` : planification quotidienne dans `AppState`, accès au dossier par signet de sécurité, section des Réglages, confirmation de restauration.
- `App/Cairn.entitlements` : droit `com.apple.security.files.bookmarks.app-scope` pour garder l'accès au dossier choisi.
- Aucune migration de la base.
