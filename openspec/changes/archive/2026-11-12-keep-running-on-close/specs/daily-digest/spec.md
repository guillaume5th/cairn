# Spec Delta

## MODIFIED Requirements

### Requirement: Heure du résumé quotidien
Le système SHALL produire un résumé par jour à l'heure réglée par l'utilisateur, 8 h par défaut. Le réglage MUST être conservé sur ce Mac entre les lancements. Le résumé est produit tant que l'app tourne, même sans fenêtre ouverte ; aucun processus ne tourne quand elle est quittée.

#### Scenario: Heure atteinte app ouverte
- **GIVEN** l'heure du résumé est 8 h et aucun résumé n'a encore été tenté aujourd'hui
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** un résumé est produit dans la minute

#### Scenario: Heure atteinte sans fenêtre
- **GIVEN** l'heure du résumé est 8 h, aucun résumé n'a encore été tenté aujourd'hui, et la fenêtre a été fermée sans quitter l'app
- **WHEN** il devient 8 h
- **THEN** un résumé est produit dans la minute et apparaît à la réouverture de la fenêtre

#### Scenario: Changement de l'heure
- **GIVEN** le résumé d'aujourd'hui n'a pas encore été tenté
- **WHEN** l'utilisateur règle l'heure sur un moment déjà passé aujourd'hui
- **THEN** le résumé d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Une seule tentative automatique par jour
- **GIVEN** le résumé d'aujourd'hui a déjà été tenté, avec succès ou non
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun autre résumé automatique n'est lancé avant le lendemain
