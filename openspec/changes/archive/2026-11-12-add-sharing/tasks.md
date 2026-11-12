# Tasks

## 1. Partager un article

- [x] 1.1 Ajouter `ShareLink` (titre et lien) dans la barre d'outils du panneau de lecture, avant « Ouvrir dans le navigateur ». Le rendre indisponible sans lien http(s). Vérifier sur Mac et sur le simulateur iPhone que la feuille de partage s'ouvre avec le titre et le lien.
- [x] 1.2 Ajouter « Partager » au menu contextuel d'un article (`ArticleMenuItems`). Vérifier sur Mac (clic droit) et sur iPhone (appui long).
- [x] 1.3 Ajouter le bouton grisé à `DisabledReaderToolbar`, à la même position. Vérifier par capture sur Mac que la barre d'outils garde la même disposition avec et sans article.

## 2. Vérification

- [x] 2.1 Vérifier que `openspec validate add-sharing --strict` passe et que les scénarios de la spec `sharing` sont vérifiés sur Mac, iPhone et iPad.

## Workflow follow-up

- Archiver le changement une fois la PR fusionnée, avec création de la spec `sharing` et synchronisation de `article-reading`.
