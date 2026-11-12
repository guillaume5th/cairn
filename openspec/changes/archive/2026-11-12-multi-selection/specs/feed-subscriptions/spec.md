# Spec Delta

## ADDED Requirements

### Requirement: Sélectionner plusieurs abonnements
Le système SHALL permettre de sélectionner plusieurs abonnements dans la barre latérale (⌘-clic, ⇧-clic) et lister alors ensemble leurs articles, du plus récent au plus ancien, comme pour un dossier. Seuls des abonnements peuvent être sélectionnés ensemble : ajouter une autre entrée (« Tous les articles », dossier, cairn, tag, « Résumés ») à la sélection MUST la remplacer par cette seule entrée.

#### Scenario: Deux abonnements sélectionnés
- **WHEN** l'utilisateur sélectionne un abonnement puis ⌘-clique sur un second
- **THEN** les articles des deux abonnements sont listés ensemble du plus récent au plus ancien, et aucun autre

#### Scenario: Ajout d'une entrée qui n'est pas un abonnement
- **GIVEN** deux abonnements sont sélectionnés
- **WHEN** l'utilisateur ⌘-clique sur un dossier
- **THEN** seul ce dossier est sélectionné

#### Scenario: Sélection multiple non mémorisée
- **GIVEN** deux abonnements sont sélectionnés
- **WHEN** l'utilisateur quitte puis relance l'app
- **THEN** la dernière entrée sélectionnée seule avant cette sélection est affichée

### Requirement: Déplacer plusieurs abonnements
Le système SHALL permettre de déplacer d'un coup les abonnements sélectionnés vers un dossier ou à la racine, par le menu contextuel « Déplacer vers » ou en faisant glisser la sélection sur un dossier.

#### Scenario: Déplacer par le menu
- **GIVEN** trois abonnements sont sélectionnés
- **WHEN** l'utilisateur choisit « Déplacer vers » puis le dossier « Cloud » dans le menu contextuel de l'un d'eux
- **THEN** les trois abonnements sont dans « Cloud »

#### Scenario: Déplacer en faisant glisser
- **GIVEN** deux abonnements sont sélectionnés
- **WHEN** l'utilisateur fait glisser l'un d'eux sur le dossier « Blogs »
- **THEN** les deux abonnements sont dans « Blogs »

### Requirement: Supprimer plusieurs abonnements
Le système SHALL permettre de supprimer d'un coup les abonnements sélectionnés après une seule confirmation, qui indique leur nombre. Chaque abonnement est supprimé comme un abonnement seul : ses articles non gardés sont supprimés, ses articles gardés conservés.

#### Scenario: Supprimer trois abonnements
- **GIVEN** trois abonnements sont sélectionnés
- **WHEN** l'utilisateur choisit « Supprimer 3 abonnements… » puis confirme
- **THEN** les trois abonnements et leurs articles non gardés sont supprimés, leurs articles gardés restent dans leur cairn, et « Tous les articles » est affiché
