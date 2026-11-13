# Spec Delta

## MODIFIED Requirements

### Requirement: Vue d'un dossier
Le système SHALL afficher, quand l'utilisateur sélectionne un dossier dans la barre latérale, les articles de tous les abonnements de ce dossier, du plus récent au plus ancien. Cette vue MUST offrir, comme celle d'un abonnement, la recherche, le filtre « Non lus » et sa propre sélection mémorisée.

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

### Requirement: Sélection d'article par défaut
Quand une entrée de la barre latérale (« Tous les articles », « Cairn », un tag, un dossier ou un abonnement) est affichée sans article mémorisé visible dans sa liste, le système SHALL n'afficher aucun article : aucune ligne n'est sélectionnée et le volet de lecture indique qu'aucun article n'est sélectionné, avec ses boutons grisés.

#### Scenario: Premier lancement
- **WHEN** l'utilisateur lance l'app pour la première fois et que « Tous les articles » contient des articles
- **THEN** aucun article n'est sélectionné et le volet de lecture indique « Aucun article sélectionné »

#### Scenario: Entrée jamais ouverte
- **WHEN** l'utilisateur sélectionne un abonnement dont aucun article n'a encore été sélectionné
- **THEN** ses articles sont listés sans qu'aucun soit sélectionné ni affiché

#### Scenario: Liste vide
- **WHEN** l'utilisateur sélectionne une entrée dont la liste ne contient aucun article
- **THEN** aucun article n'est sélectionné et le panneau de lecture indique qu'aucun article n'est sélectionné

### Requirement: Sélection mémorisée par entrée
Le système SHALL retenir, pour chaque entrée de la barre latérale, le dernier article sélectionné, et le sélectionner de nouveau quand l'utilisateur revient sur cette entrée. Chaque abonnement et chaque tag a sa propre mémoire.

#### Scenario: Retour sur « Tous les articles »
- **GIVEN** l'utilisateur a sélectionné le troisième article de « Tous les articles »
- **WHEN** il ouvre « Cairn » ou un abonnement, puis revient sur « Tous les articles »
- **THEN** le troisième article est de nouveau sélectionné et affiché

#### Scenario: Mémoires indépendantes
- **GIVEN** l'utilisateur a sélectionné l'article A dans l'abonnement X et l'article B dans l'abonnement Y
- **WHEN** il revient sur l'abonnement X
- **THEN** l'article A est sélectionné

#### Scenario: Article mémorisé absent de la liste
- **GIVEN** l'article mémorisé d'une entrée n'est plus dans sa liste (filtre « Non lus », recherche, purge, suppression ou désabonnement)
- **WHEN** l'utilisateur revient sur cette entrée
- **THEN** aucun article n'est sélectionné et le volet de lecture indique « Aucun article sélectionné »

### Requirement: État lu / non lu
Le système SHALL marquer un article comme lu quand l'utilisateur le sélectionne lui-même (clic ou clavier) et qu'il est le seul article sélectionné, et MUST permettre de le remettre manuellement en non lu ou de marquer tous les articles de la liste courante comme lus. Un article sélectionné automatiquement (sélection mémorisée) ou faisant partie d'une sélection de plusieurs articles MUST être affiché ou sélectionné sans que son état lu change.

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur sélectionne lui-même un article non lu
- **THEN** l'article est marqué lu et le compteur de non lus de son abonnement diminue

#### Scenario: Sélection automatique
- **WHEN** un article non lu mémorisé est sélectionné de nouveau à l'ouverture d'une entrée ou au lancement
- **THEN** il est affiché et reste non lu

#### Scenario: Filtre « Non lus » et sélection automatique
- **WHEN** le filtre « Non lus » est actif et que l'article non lu mémorisé est sélectionné de nouveau à l'ouverture de l'entrée
- **THEN** il reste non lu et visible dans la liste, et aucun autre article n'est marqué lu

#### Scenario: Tout marquer comme lu
- **WHEN** l'utilisateur choisit « Tout marquer comme lu » sur la liste courante
- **THEN** tous les articles de cette liste deviennent lus

#### Scenario: Sélection multiple
- **WHEN** l'utilisateur sélectionne trois articles non lus au ⌘-clic
- **THEN** les trois restent non lus
