# Proposal

## Why

Les images d'un article (schémas, captures, graphiques) sont limitées à la largeur de la colonne de lecture, souvent trop petite pour les lire. Il faut aujourd'hui ouvrir l'article dans le navigateur pour les agrandir. Coup d'œil (Quick Look) est la manière macOS de regarder une image en grand, et de passer aux suivantes.

## What Changes

- Cliquer sur une image de l'article l'ouvre dans Coup d'œil, en grand. Les autres images de l'article y sont parcourables avec les flèches.
- Une image qui est aussi un lien garde son comportement de lien : le clic ouvre le lien dans le navigateur.
- Le contenu des flux reste sans script : le clic est détecté par un script de l'app, isolé de la page, comme le surlignage de la recherche.

## Capabilities

### New Capabilities

### Modified Capabilities
- `article-reading`: ajout d'une exigence « Agrandir une image avec Coup d'œil ». « Afficher un article » ne change pas : aucun script de l'article ne s'exécute.

## Impact

- `App/HTMLView.swift` : un script utilisateur dans le monde de l'app et un gestionnaire de messages sur la `WebPage`, et l'affichage de Coup d'œil (`.quickLookPreview`).
- Téléchargement des images de l'article vers un dossier temporaire, effacé au changement d'article.
- `CairnCore` : une fonction pure qui choisit les adresses d'images acceptées et leur nom de fichier, avec ses tests.
- Aucune dépendance ajoutée.
- Hors périmètre : enregistrer ou partager une image depuis Cairn (Coup d'œil propose déjà de l'ouvrir dans Aperçu), vidéos.
