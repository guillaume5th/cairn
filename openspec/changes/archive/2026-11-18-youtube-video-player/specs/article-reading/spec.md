# Spec Delta

## ADDED Requirements

### Requirement: Regarder une vidéo YouTube
Le système SHALL afficher, sous l'en-tête d'un article dont le lien est une vidéo YouTube, un lecteur vidéo intégré, avec un bouton « Ouvrir sur YouTube » toujours visible. La lecture MUST s'arrêter quand l'utilisateur change d'article. Le lecteur MUST NOT charger de contenu hors des domaines de YouTube. Un article dont le lien n'est pas une vidéo YouTube MUST NOT afficher de lecteur.

#### Scenario: Vidéo d'une chaîne suivie
- **GIVEN** un article dont le lien est `https://www.youtube.com/watch?v=nHz3mJpo9BE`
- **WHEN** l'utilisateur ouvre cet article
- **THEN** un lecteur permet de regarder cette vidéo sous l'en-tête, au-dessus du contenu de l'article

#### Scenario: Lien court
- **GIVEN** un article dont le lien est `https://youtu.be/nHz3mJpo9BE`
- **WHEN** l'utilisateur ouvre cet article
- **THEN** le lecteur affiche la même vidéo

#### Scenario: Article hors YouTube
- **WHEN** l'utilisateur ouvre un article dont le lien n'est pas une vidéo YouTube, ou une chaîne ou une playlist YouTube
- **THEN** aucun lecteur n'est affiché

#### Scenario: Changement d'article
- **GIVEN** une vidéo en cours de lecture
- **WHEN** l'utilisateur sélectionne un autre article
- **THEN** la lecture s'arrête

#### Scenario: Intégration refusée
- **GIVEN** une vidéo dont le propriétaire interdit l'intégration
- **WHEN** l'utilisateur ouvre l'article
- **THEN** le lecteur montre le refus de YouTube et le bouton « Ouvrir sur YouTube » ouvre la vidéo dans le navigateur par défaut

#### Scenario: Contenu de l'article inchangé
- **WHEN** l'article d'une vidéo est affiché avec son lecteur
- **THEN** le contenu de l'article reste affiché sans exécuter de script ni charger de contenu distant autre que les images

## MODIFIED Requirements

### Requirement: Afficher un article
Le système SHALL afficher le titre, la source, la date et le contenu fourni par le flux de l'article sélectionné, mis en forme (HTML rendu). Le contenu MUST être affiché sans exécuter de script ni charger de contenu distant autre que les images. Pour un article dont le lien est une vidéo YouTube, la vidéo tient lieu de contenu quand le flux n'en fournit pas.

#### Scenario: Sélection d'un article
- **WHEN** l'utilisateur sélectionne un article
- **THEN** son contenu s'affiche dans le panneau de lecture

#### Scenario: Article sans contenu
- **WHEN** l'article sélectionné n'a ni contenu ni résumé dans le flux, et que son lien n'est pas une vidéo YouTube
- **THEN** le panneau indique qu'aucun contenu n'est disponible et propose de l'ouvrir dans le navigateur

#### Scenario: Vidéo YouTube sans contenu
- **WHEN** l'article sélectionné est une vidéo YouTube dont le flux ne fournit ni contenu ni résumé
- **THEN** le lecteur vidéo occupe le panneau de lecture, sans message d'absence de contenu
