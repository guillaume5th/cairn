## ADDED Requirements

### Requirement: Vue « Aujourd'hui »
Le système SHALL proposer dans la barre latérale, sous « Tous les articles », une entrée « Aujourd'hui » qui affiche les articles de tous les abonnements publiés depuis minuit (heure locale), avec à côté le nombre de ces articles non lus, sans nombre quand il n'y en a aucun. Cette vue MUST se comporter comme « Tous les articles » pour la recherche, le filtre « Non lus », l'ordre et le prochain non lu.

#### Scenario: Articles du jour
- **GIVEN** un article publié ce matin et un autre hier soir
- **WHEN** l'utilisateur sélectionne « Aujourd'hui »
- **THEN** seul l'article de ce matin est affiché

#### Scenario: Compteur
- **GIVEN** trois articles publiés aujourd'hui, dont deux non lus
- **WHEN** l'utilisateur regarde la barre latérale
- **THEN** « Aujourd'hui » affiche 2
