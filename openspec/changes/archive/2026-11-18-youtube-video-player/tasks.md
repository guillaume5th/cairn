# Tasks

## 1. Identifiant de la vidéo

- [x] 1.1 Ajouter `Library.youtubeVideoID(in:)` dans CairnCore et vérifier avec des tests : `watch?v=`, `youtu.be/`, `m.youtube.com`, liens avec paramètres supplémentaires, puis nil pour une chaîne, une playlist, un Shorts, un autre domaine et un identifiant mal formé (`swift test` dans CairnCore)

## 2. Lecteur dans l'app

- [x] 2.1 Créer `App/VideoPlayer.swift` : `WebPage` non persistante avec JavaScript actif qui charge l'embed `youtube-nocookie.com`, un décideur de navigation limité aux domaines YouTube (liens cliqués ouverts dans le navigateur), et le bouton « Ouvrir sur YouTube » dessous ; vérifier que le build passe
- [x] 2.2 Insérer le lecteur dans `ArticleDetailView`, sous l'en-tête et au-dessus de la vue du contenu, recréé par identifiant de vidéo ; vérifier qu'un article sans lien YouTube n'affiche aucun lecteur
- [x] 2.3 Vérifier dans Cairn Dev avec `cairn-run` : la vidéo de Nicolas Martignole se lit, un changement d'article coupe le son, le bouton « Ouvrir sur YouTube » ouvre le navigateur, et une vidéo non intégrable montre le refus de YouTube (si le refus 153 apparaît à tort, appliquer le repli `baseURL` de design.md)

## 3. La vidéo comme contenu

- [x] 3.1 Dans `ArticleDetailView`, ne pas afficher « Aucun contenu » quand l'article est une vidéo sans contenu, et laisser le lecteur remplir la largeur du panneau ; vérifier dans Cairn Dev que la vidéo de Nicolas Martignole s'affiche sans message d'absence de contenu et qu'un article sans contenu ni vidéo l'affiche toujours
