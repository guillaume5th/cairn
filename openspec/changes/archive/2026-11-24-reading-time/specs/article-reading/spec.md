# Spec Delta

## ADDED Requirements

### Requirement: Temps de lecture estimé
Le système SHALL afficher le temps de lecture estimé d'un article dans son en-tête et dans sa ligne de la liste, calculé depuis son texte lisible (le texte intégral s'il est chargé, sinon le contenu du flux) à 230 mots par minute, arrondi à la minute la plus proche et d'au moins 1 minute. Un article sans texte MUST NOT afficher de temps.

#### Scenario: Article de quatorze minutes
- **GIVEN** un article de 3 200 mots
- **WHEN** l'utilisateur le sélectionne
- **THEN** son en-tête affiche « · 14 min read » après la date, et sa ligne de la liste affiche « 14 min » avec l'icône de chronomètre à côté de la source

#### Scenario: Place dans la liste
- **WHEN** la ligne d'un article affiche son temps de lecture
- **THEN** il suit le nom de la source, avec une icône de chronomètre, et la date relative reste seule à droite

#### Scenario: Article très court
- **GIVEN** un article de quelques mots
- **WHEN** il est affiché
- **THEN** son temps de lecture est de 1 minute

#### Scenario: Article sans contenu
- **GIVEN** un article dont le flux ne fournit aucun texte
- **WHEN** il est affiché
- **THEN** ni l'en-tête ni la ligne de la liste n'affichent de temps de lecture

#### Scenario: Texte intégral chargé
- **GIVEN** un article dont le flux ne donne qu'un extrait
- **WHEN** l'utilisateur charge le texte intégral
- **THEN** le temps de lecture est recalculé sur le texte intégral

#### Scenario: Libellé localisé
- **WHEN** l'application est en français
- **THEN** l'en-tête affiche « min de lecture » au lieu de « min read »
