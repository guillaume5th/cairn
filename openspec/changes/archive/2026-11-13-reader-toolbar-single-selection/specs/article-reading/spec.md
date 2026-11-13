# Spec Delta

## MODIFIED Requirements

### Requirement: Barre d'outils du volet sans article
Le système SHALL, quand le volet de lecture n'affiche pas un article (aucun article sélectionné, sélection multiple ou mode sélection), y garder les boutons de lecture à leur place, comme Mail, pour que la barre d'outils ne change pas de disposition. Avec au moins un article sélectionné, Garder, Marquer et Ouvrir dans le navigateur MUST être actifs et porter sur la sélection ; Partager MUST être actif quand un seul article est sélectionné ; les autres boutons sont grisés.

#### Scenario: Entrer en mode sélection
- **GIVEN** un article est affiché dans le volet de lecture
- **WHEN** l'utilisateur active le mode sélection
- **THEN** les boutons de lecture restent à leur place et ceux de la liste ne bougent pas

#### Scenario: Aucun article sélectionné
- **WHEN** le volet de lecture indique « Aucun article sélectionné »
- **THEN** les boutons Article complet, Résumer, Garder, Marquer, Partager et Ouvrir dans le navigateur sont à leur place, tous grisés

#### Scenario: Actions d'une sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur regarde la barre d'outils du volet de lecture
- **THEN** Garder, Marquer comme lu et Ouvrir dans le navigateur sont actifs, et Article complet, Résumer et Partager sont grisés

#### Scenario: Un seul article coché
- **GIVEN** le mode sélection est actif et un seul article est coché
- **WHEN** l'utilisateur choisit Partager dans la barre d'outils du volet de lecture
- **THEN** la feuille de partage s'ouvre avec le titre et le lien de cet article

### Requirement: État lu / non lu
Le système SHALL marquer un article comme lu quand l'utilisateur le sélectionne lui-même (clic ou clavier) et qu'il est le seul article sélectionné, et MUST permettre de le remettre manuellement en non lu ou en lu, ou de marquer tous les articles de la liste courante comme lus. Un article sélectionné automatiquement (sélection mémorisée) ou faisant partie d'une sélection de plusieurs articles MUST être affiché ou sélectionné sans que son état lu change.

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

#### Scenario: Basculer l'article affiché
- **GIVEN** l'article affiché est lu
- **WHEN** l'utilisateur choisit « Marquer comme non lu » dans la barre d'outils, puis le même bouton, devenu « Marquer comme lu »
- **THEN** l'article redevient non lu, puis de nouveau lu
