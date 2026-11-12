# Spec Delta

## ADDED Requirements

### Requirement: Sélectionner plusieurs articles
Le système SHALL permettre de sélectionner plusieurs articles dans toute liste d'articles avec les gestes standard du Mac : ⌘-clic pour ajouter ou retirer un article, ⇧-clic ou ⇧-flèche pour étendre la sélection, ⌘A pour tout sélectionner. Une action choisie dans le menu contextuel d'un article sélectionné MUST s'appliquer à toute la sélection ; sur un article non sélectionné, elle ne porte que sur lui.

#### Scenario: Sélection au ⌘-clic
- **GIVEN** un article est sélectionné
- **WHEN** l'utilisateur ⌘-clique sur deux autres articles
- **THEN** les trois articles sont sélectionnés

#### Scenario: Tout sélectionner
- **WHEN** l'utilisateur appuie sur ⌘A dans une liste de vingt articles
- **THEN** les vingt articles sont sélectionnés

#### Scenario: Menu contextuel sur la sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur fait un clic droit sur l'un d'eux et choisit une action
- **THEN** l'action s'applique aux trois articles

#### Scenario: Menu contextuel hors de la sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur fait un clic droit sur un quatrième article et choisit une action
- **THEN** l'action ne s'applique qu'à ce quatrième article

### Requirement: Volet de lecture d'une sélection multiple
Le système SHALL, quand plusieurs articles sont sélectionnés, afficher dans le volet de lecture le nombre d'articles sélectionnés (« N articles sélectionnés ») au lieu d'un article, avec les actions qui s'appliquent à toute la sélection.

#### Scenario: Plusieurs articles sélectionnés
- **WHEN** l'utilisateur sélectionne trois articles
- **THEN** le volet de lecture affiche « 3 articles sélectionnés » et les actions sur la sélection

#### Scenario: Retour à un seul article
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur clique sur un seul article sans touche de modification
- **THEN** cet article est affiché comme d'habitude

### Requirement: Marquer plusieurs articles comme lus ou non lus
Le système SHALL permettre de marquer toute la sélection comme lue ou non lue. Quand au moins un article de la sélection est non lu, l'action proposée MUST être « Marquer comme lu » ; sinon « Marquer comme non lu ».

#### Scenario: Sélection en partie non lue
- **GIVEN** deux articles lus et un non lu sont sélectionnés
- **WHEN** l'utilisateur choisit « Marquer comme lu »
- **THEN** les trois articles sont lus

#### Scenario: Sélection entièrement lue
- **GIVEN** trois articles lus sont sélectionnés
- **WHEN** l'utilisateur choisit « Marquer comme non lu »
- **THEN** les trois articles redeviennent non lus et les compteurs augmentent de trois

### Requirement: Ouvrir plusieurs articles dans le navigateur
Le système SHALL permettre d'ouvrir le lien de chaque article sélectionné dans le navigateur par défaut. Au-delà de 10 articles, le système MUST demander confirmation avant de les ouvrir.

#### Scenario: Ouvrir trois articles
- **WHEN** l'utilisateur choisit « Ouvrir dans le navigateur » avec trois articles sélectionnés
- **THEN** les trois liens s'ouvrent dans le navigateur

#### Scenario: Ouvrir beaucoup d'articles
- **WHEN** l'utilisateur choisit « Ouvrir dans le navigateur » avec quinze articles sélectionnés
- **THEN** le système demande confirmation avant d'ouvrir les quinze liens

### Requirement: Sélection multiple non mémorisée
Le système MUST NOT retenir une sélection multiple, ni par entrée ni d'un lancement à l'autre : seule une sélection d'un article est mémorisée. Quitter une entrée avec plusieurs articles sélectionnés MUST laisser sa mémoire telle qu'elle était avant la sélection multiple.

#### Scenario: Revenir sur l'entrée
- **GIVEN** l'utilisateur avait l'article A sélectionné dans un abonnement, puis a sélectionné trois articles
- **WHEN** il ouvre une autre entrée puis revient sur cet abonnement
- **THEN** seul l'article A est sélectionné

## MODIFIED Requirements

### Requirement: État lu / non lu
Le système SHALL marquer un article comme lu quand l'utilisateur le sélectionne lui-même (clic ou clavier) et qu'il est le seul article sélectionné, et MUST permettre de le remettre manuellement en non lu ou de marquer tous les articles de la liste courante comme lus. Un article sélectionné automatiquement (sélection par défaut ou mémorisée) ou faisant partie d'une sélection de plusieurs articles MUST être affiché ou sélectionné sans que son état lu change.

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur sélectionne lui-même un article non lu
- **THEN** l'article est marqué lu et le compteur de non lus de son abonnement diminue

#### Scenario: Sélection automatique
- **WHEN** un article non lu est sélectionné automatiquement à l'ouverture d'une entrée ou au lancement
- **THEN** il est affiché et reste non lu

#### Scenario: Filtre « Non lus » et sélection automatique
- **WHEN** le filtre « Non lus » est actif et que le premier article est sélectionné automatiquement
- **THEN** il reste non lu et visible dans la liste, et aucun autre article n'est marqué lu

#### Scenario: Tout marquer comme lu
- **WHEN** l'utilisateur choisit « Tout marquer comme lu » sur la liste courante
- **THEN** tous les articles de cette liste deviennent lus

#### Scenario: Sélection multiple
- **WHEN** l'utilisateur sélectionne trois articles non lus au ⌘-clic
- **THEN** les trois restent non lus
