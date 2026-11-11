# Spec Delta

## ADDED Requirements

### Requirement: Compteur de non lus de « Tous les articles »
Le système SHALL afficher dans la barre latérale, à côté de « Tous les articles », le nombre d'articles non lus de cette liste, y compris les articles gardés dont l'abonnement a été supprimé. Ce nombre MUST NOT dépendre du filtre « Non lus ». Aucun nombre n'est affiché quand il n'y a aucun article non lu.

#### Scenario: Articles non lus
- **WHEN** la liste « Tous les articles » contient 7 articles non lus
- **THEN** « Tous les articles » affiche 7 dans la barre latérale

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur sélectionne lui-même un article non lu
- **THEN** le nombre de « Tous les articles » diminue de 1, comme celui de son abonnement

#### Scenario: Article gardé sans abonnement
- **GIVEN** un article gardé non lu dont l'abonnement a été supprimé
- **WHEN** l'utilisateur regarde la barre latérale
- **THEN** cet article est compté dans le nombre de « Tous les articles »

#### Scenario: Filtre « Non lus »
- **WHEN** l'utilisateur active ou désactive le filtre « Non lus »
- **THEN** le nombre de « Tous les articles » ne change pas

#### Scenario: Tout est lu
- **WHEN** aucun article n'est non lu
- **THEN** « Tous les articles » n'affiche aucun nombre
