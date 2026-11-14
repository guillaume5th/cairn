## ADDED Requirements

### Requirement: Masquer les doublons
Le système SHALL n'afficher qu'un article par lien normalisé dans les listes qui réunissent plusieurs abonnements : « Tous les articles », « Aujourd'hui », la vue d'un dossier et la sélection de plusieurs abonnements, y compris pendant une recherche ou avec le filtre « Non lus ». L'article affiché MUST être, dans cet ordre, un exemplaire gardé, sinon un exemplaire non lu, sinon le plus récent. La vue d'un abonnement et les vues de cairn et de tag MUST continuer d'afficher tous leurs articles.

#### Scenario: Liste de tous les articles
- **GIVEN** le même lien est arrivé par « Blog » et par « Agrégateur »
- **WHEN** l'utilisateur ouvre « Tous les articles »
- **THEN** une seule ligne montre cet article

#### Scenario: Vue d'un abonnement
- **GIVEN** le même lien est arrivé par « Blog » et par « Agrégateur »
- **WHEN** l'utilisateur ouvre « Agrégateur »
- **THEN** l'exemplaire d'« Agrégateur » est listé

#### Scenario: Exemplaire gardé
- **GIVEN** l'exemplaire d'« Agrégateur » est gardé et celui de « Blog » ne l'est pas
- **WHEN** l'utilisateur ouvre « Tous les articles »
- **THEN** la ligne affichée est l'exemplaire gardé, avec sa marque de cairn
