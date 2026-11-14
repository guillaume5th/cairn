## ADDED Requirements

### Requirement: Renommer et supprimer un tag
Le système SHALL proposer « Renommer… » et « Supprimer le tag… » dans le menu contextuel d'un tag de la barre latérale. Le renommage MUST valoir pour tous les cairns ; un nom déjà porté par un autre tag (casse et accents ignorés) MUST fusionner les deux tags. La suppression MUST retirer le tag de tous les articles, après une confirmation indiquant leur nombre.

#### Scenario: Corriger une faute
- **WHEN** l'utilisateur renomme le tag « swfit » en « swift », qui n'existe pas encore
- **THEN** les articles qui portaient « swfit » portent « swift », dans tous les cairns

#### Scenario: Fusionner deux tags
- **GIVEN** des articles portent « IA » et d'autres « intelligence artificielle »
- **WHEN** l'utilisateur renomme « intelligence artificielle » en « ia »
- **THEN** tous ces articles portent le seul tag « IA »

#### Scenario: Supprimer un tag
- **WHEN** l'utilisateur supprime le tag « brouillon » et confirme
- **THEN** plus aucun article ne porte ce tag et il disparaît de la barre latérale
