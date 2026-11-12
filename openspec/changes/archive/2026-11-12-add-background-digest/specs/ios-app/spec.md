# Spec Delta

## ADDED Requirements

### Requirement: Rafraîchissement en arrière-plan sur iOS
Le système SHALL demander à iOS de rafraîchir les abonnements en arrière-plan, au plus une fois par heure, pour que la liste soit à jour à l'ouverture. Le moment exact et la fréquence MUST rester décidés par iOS ; l'app ne promet aucune heure.

#### Scenario: Liste à jour à l'ouverture
- **GIVEN** Cairn est en arrière-plan depuis plusieurs heures et iOS a accordé un rafraîchissement
- **WHEN** l'utilisateur revient dans l'app
- **THEN** les articles publiés pendant ce temps sont déjà listés

#### Scenario: Rafraîchissement en arrière-plan désactivé
- **GIVEN** l'utilisateur a désactivé l'actualisation en arrière-plan pour Cairn dans les réglages d'iOS
- **WHEN** l'app revient au premier plan
- **THEN** les abonnements sont rafraîchis comme aujourd'hui, au retour dans l'app

### Requirement: Résumé quotidien en arrière-plan sur iOS
Le système SHALL demander à iOS d'exécuter le résumé quotidien en arrière-plan à partir de l'heure réglée. Quand iOS lui en donne l'occasion et qu'aucun résumé n'a été tenté ce jour-là, le système rafraîchit les abonnements puis produit le résumé. Si le moteur d'IA ne peut pas travailler en arrière-plan, la tentative MUST NOT compter pour la journée : le résumé est produit au retour dans l'app.

#### Scenario: Résumé prêt au réveil
- **GIVEN** l'heure du résumé est 8 h, l'app est en arrière-plan et iOS lui accorde du temps après 8 h
- **WHEN** l'utilisateur ouvre Cairn à 9 h
- **THEN** le résumé du jour est déjà là, sans attente

#### Scenario: Moteur indisponible en arrière-plan
- **GIVEN** le moteur choisi ne peut pas travailler en arrière-plan
- **WHEN** iOS accorde du temps à l'app après l'heure du résumé
- **THEN** aucun résumé n'est enregistré comme tenté et le résumé est produit au retour dans l'app

#### Scenario: iOS n'accorde pas de temps
- **GIVEN** iOS n'a donné aucune occasion à l'app depuis l'heure du résumé
- **WHEN** l'utilisateur revient dans l'app
- **THEN** le résumé du jour est produit à ce moment, comme aujourd'hui

## REMOVED Requirements

### Requirement: Résumé quotidien au premier plan
**Reason**: Le résumé et le rafraîchissement peuvent désormais se faire en arrière-plan quand iOS le permet.
**Migration**: Remplacée par « Résumé quotidien en arrière-plan sur iOS » ; le rattrapage au retour dans l'app reste assuré par « Rattrapage au lancement » de `daily-digest`.
