# Proposal

## Why

« Garder » range un article dans un cairn pour toujours, avec note et tags. Pour un article simplement repéré (« je le lirai ce soir »), c'est trop : il encombre le cairn et il faut penser à le retirer. Créer un cairn « Lire plus tard » ne règle pas le problème, puisque l'article y reste une fois lu.

## What Changes

- Une marque « Lire plus tard », indépendante de « garder » : pas de cairn, pas de note, pas de tags.
- Une entrée « Lire plus tard » dans la barre latérale, sous « Aujourd'hui », avec le nombre d'articles en attente, qui liste la file du plus récemment ajouté au plus ancien.
- Un article sort de la file dès qu'il est lu ; l'article lu reste affiché dans la liste tant qu'il est sélectionné.
- Ajouter un article déjà lu à la file le remet en non lu.
- Action « Lire plus tard » / « Retirer de Lire plus tard » dans le menu contextuel, le menu Article (⇧⌘D, comme la liste de lecture de Safari) et la barre d'outils du volet de lecture, sur un article ou une sélection.
- Un article dans la file n'est pas purgé.
- La sauvegarde contient la marque et la restauration la rétablit.

## Capabilities

### New Capabilities
- `read-later`: la file « Lire plus tard » : ajout, retrait, vue dédiée, sortie à la lecture.

### Modified Capabilities
- `article-reading`: la purge épargne les articles de la file ; le menu Article gagne l'action « Lire plus tard » et son raccourci.
- `backup`: la sauvegarde contient la marque « Lire plus tard ».

## Impact

- `CairnCore` : `Models.swift` (`Article.readLaterAt`), `Library.swift` (ajout/retrait, purge), `Backup.swift` (champ optionnel, compatible avec les anciennes sauvegardes), tests.
- `App` : `ContentView.swift` (`SidebarItem.readLater`, liste filtrée), `SidebarView.swift` (entrée et compteur), `ArticleDetailView.swift` (bouton, `ArticleMenuItems`).
- Schéma SwiftData/CloudKit : un attribut optionnel, sans migration.
