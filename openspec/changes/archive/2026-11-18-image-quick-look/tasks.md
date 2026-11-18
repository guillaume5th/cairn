# Tasks

## 1. Adresses des images

- [x] 1.1 Ajouter `Library.quickLookImages(_:)` dans CairnCore et vérifier avec des tests : `https:` et `data:image` gardés dans l'ordre, `http:`, `javascript:` et `file:` rejetés, doublons retirés, limite de 50, noms de fichier sûrs avec l'extension du type MIME ou de l'adresse (`swift test --only-use-versions-from-resolved-file`)

## 2. Coup d'œil dans le lecteur

- [x] 2.1 Dans `HTMLView`, ajouter le script utilisateur (monde `.defaultClient`) et le gestionnaire de messages, télécharger les images dans le dossier temporaire et ouvrir `.quickLookPreview` ; effacer le dossier au changement d'article ; vérifier que le build passe
- [x] 2.2 Vérifier dans Cairn Dev avec `cairn-run` : clic sur une image ouvre Coup d'œil sur elle, les flèches passent aux autres, une image-lien ouvre le navigateur, changer d'article ferme Coup d'œil et vide le dossier temporaire
