## ADDED Requirements

### Requirement: Progression de lecture
Le système SHALL afficher sous l'en-tête de l'article, au-dessus de son résumé, une fine barre de progression qui suit le défilement : vide quand le haut de l'article est visible, pleine quand sa fin est visible. La barre MUST être absente quand l'article tient entièrement dans le volet. La progression MUST NOT être mémorisée : un article rouvert s'affiche en haut, barre vide.

#### Scenario: Défiler dans un long article
- **GIVEN** un article plus haut que le volet de lecture est affiché en haut
- **WHEN** l'utilisateur fait défiler jusqu'à la moitié de l'article
- **THEN** la barre de progression est à moitié remplie

#### Scenario: Fin de l'article
- **WHEN** l'utilisateur fait défiler jusqu'à la fin d'un long article
- **THEN** la barre de progression est pleine

#### Scenario: Avec un résumé
- **GIVEN** l'article affiché a un résumé
- **WHEN** l'utilisateur fait défiler l'article
- **THEN** la barre de progression est entre l'en-tête et le résumé

#### Scenario: Article court
- **WHEN** l'article affiché tient entièrement dans le volet
- **THEN** aucune barre de progression n'est affichée

#### Scenario: Rouvrir un article
- **GIVEN** l'utilisateur a lu la moitié d'un long article puis en a ouvert un autre
- **WHEN** il rouvre le premier article
- **THEN** l'article s'affiche en haut et la barre est vide
