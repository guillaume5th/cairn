## ADDED Requirements

### Requirement: Inspecteur d'un article
Le système SHALL afficher la note et les tags de l'article lu dans un inspecteur à droite du volet de lecture, et non sous l'article. L'inspecteur MUST s'ouvrir et se fermer par un bouton de la barre d'outils du volet de lecture et par une commande du menu Présentation, et son état ouvert ou fermé MUST être conservé entre les lancements. Il est ouvert par défaut.

#### Scenario: Article gardé
- **GIVEN** l'inspecteur est ouvert
- **WHEN** l'utilisateur lit un article gardé
- **THEN** l'inspecteur montre son cairn, la date où il a été gardé, ses notes sous le titre « Notes » et ses tags

#### Scenario: Article non gardé
- **GIVEN** l'inspecteur est ouvert
- **WHEN** l'utilisateur lit un article non gardé
- **THEN** l'inspecteur indique qu'il faut garder l'article pour lui ajouter des notes et des tags, et propose de le garder

#### Scenario: Fermer l'inspecteur
- **WHEN** l'utilisateur ferme l'inspecteur puis relance l'application
- **THEN** l'inspecteur est fermé et l'article occupe toute la largeur du volet de lecture

#### Scenario: Changer de cairn depuis l'inspecteur
- **GIVEN** il existe les cairns « Perso » et « Pro » et l'article est gardé dans « Perso »
- **WHEN** l'utilisateur choisit « Pro » dans l'inspecteur
- **THEN** l'article passe dans « Pro » avec ses notes et ses tags

#### Scenario: Tags en capsules
- **WHEN** l'utilisateur ajoute le tag « swift » dans l'inspecteur
- **THEN** « swift » apparaît en capsule aux couleurs système, avec un bouton pour le retirer
