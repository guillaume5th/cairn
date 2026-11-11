## ADDED Requirements

### Requirement: Vue d'un dossier
Le système SHALL afficher, quand l'utilisateur sélectionne un dossier dans la barre latérale, les articles de tous les abonnements de ce dossier, du plus récent au plus ancien. Cette vue MUST offrir, comme celle d'un abonnement, la recherche, le filtre « Non lus », la sélection par défaut et sa propre sélection mémorisée.

#### Scenario: Sélection d'un dossier
- **WHEN** l'utilisateur sélectionne un dossier contenant deux abonnements
- **THEN** les articles des deux abonnements sont listés ensemble du plus récent au plus ancien, et aucun autre

#### Scenario: Recherche dans un dossier
- **WHEN** l'utilisateur recherche un mot dans la vue d'un dossier
- **THEN** seuls les articles des abonnements de ce dossier qui contiennent ce mot sont listés

#### Scenario: Mémoire du dossier
- **GIVEN** l'utilisateur a sélectionné un article dans la vue d'un dossier
- **WHEN** il ouvre une autre entrée puis revient sur ce dossier
- **THEN** le même article est de nouveau sélectionné

#### Scenario: Dossier vide
- **WHEN** l'utilisateur sélectionne un dossier sans abonnement
- **THEN** la liste est vide et aucun article n'est sélectionné

#### Scenario: Dossier supprimé
- **WHEN** le dossier affiché est supprimé
- **THEN** la vue « Tous les articles » est affichée
