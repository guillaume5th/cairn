## ADDED Requirements

### Requirement: Marquer lu par balayage
Le système SHALL proposer, en balayant vers la droite une ligne de la liste d'articles, « Marquer comme lu » pour un article non lu et « Marquer comme non lu » pour un article lu. L'action MUST porter sur l'article de la ligne seul et MUST NOT changer la sélection.

#### Scenario: Marquer lu
- **GIVEN** un article non lu n'est pas sélectionné
- **WHEN** l'utilisateur balaie sa ligne vers la droite et choisit « Marquer comme lu »
- **THEN** l'article est lu, le compteur de non lus de son abonnement diminue et la sélection est inchangée

#### Scenario: Marquer non lu
- **WHEN** l'utilisateur balaie vers la droite la ligne d'un article lu et choisit « Marquer comme non lu »
- **THEN** l'article redevient non lu

### Requirement: Mettre de côté par balayage
Le système SHALL proposer, en balayant vers la gauche une ligne de la liste d'articles, « Lire plus tard » (« Retirer de Lire plus tard » pour un article dans la file) et « Retirer du cairn » pour un article gardé. « Garder dans le cairn » MUST être proposé pour un article non gardé seulement s'il n'existe qu'un cairn. Retirer un article qui a des notes ou des tags MUST demander confirmation, comme ailleurs. L'action MUST NOT changer la sélection ni marquer l'article lu.

#### Scenario: Lire plus tard
- **WHEN** l'utilisateur balaie vers la gauche la ligne d'un article hors de la file et choisit « Lire plus tard »
- **THEN** l'article entre dans la file « Lire plus tard », non lu

#### Scenario: Garder avec un seul cairn
- **GIVEN** il n'existe qu'un cairn et l'article n'est pas gardé
- **WHEN** l'utilisateur balaie sa ligne vers la gauche et choisit « Garder dans le cairn »
- **THEN** l'article est gardé dans ce cairn

#### Scenario: Plusieurs cairns
- **GIVEN** il existe les cairns « Perso » et « Pro » et l'article n'est pas gardé
- **WHEN** l'utilisateur balaie sa ligne vers la gauche
- **THEN** seule l'action « Lire plus tard » est proposée

#### Scenario: Retirer un article annoté
- **GIVEN** un article gardé a une note
- **WHEN** l'utilisateur balaie sa ligne vers la gauche et choisit « Retirer du cairn »
- **THEN** une confirmation annonce que ses notes et ses tags seront perdus, et l'article n'est retiré qu'après confirmation
