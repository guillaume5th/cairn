# Spec Delta

## Purpose

La file « Lire plus tard » met de côté des articles à lire bientôt, sans les garder dans un cairn : ils en sortent d'eux-mêmes une fois lus.

## ADDED Requirements

### Requirement: Mettre un article dans la file
Le système SHALL permettre d'ajouter un article à la file « Lire plus tard » et de l'en retirer, indépendamment de « garder » : l'article n'est rangé dans aucun cairn et ne reçoit ni note ni tag. Un article déjà lu ajouté à la file MUST redevenir non lu.

#### Scenario: Ajouter un article non lu
- **WHEN** l'utilisateur choisit « Lire plus tard » sur un article non lu
- **THEN** l'article apparaît dans la vue « Lire plus tard » et n'apparaît dans aucun cairn

#### Scenario: Ajouter un article déjà lu
- **WHEN** l'utilisateur choisit « Lire plus tard » sur un article lu
- **THEN** l'article redevient non lu et apparaît dans la vue « Lire plus tard »

#### Scenario: Retirer de la file
- **WHEN** l'utilisateur choisit « Retirer de Lire plus tard » sur un article de la file
- **THEN** l'article disparaît de la vue « Lire plus tard » et son état lu ne change pas

#### Scenario: Article gardé
- **GIVEN** un article est gardé dans le cairn « Pro »
- **WHEN** l'utilisateur l'ajoute à la file
- **THEN** il est à la fois dans « Pro » et dans « Lire plus tard », avec sa note et ses tags

### Requirement: Sortie de la file à la lecture
Un article de la file SHALL en sortir dès qu'il est lu, et y revenir s'il est remis en non lu, quelle que soit la façon dont il le devient (sélection, « Marquer comme lu », « Tout marquer comme lu »). L'article affiché MUST rester dans la liste de la vue « Lire plus tard » tant qu'il est sélectionné.

#### Scenario: Lire un article de la file
- **WHEN** l'utilisateur sélectionne un article dans la vue « Lire plus tard »
- **THEN** l'article est affiché, reste dans la liste, et n'y est plus quand l'utilisateur sélectionne un autre article ou quitte la vue

#### Scenario: Marquer comme lu ailleurs
- **WHEN** l'utilisateur lit, depuis son abonnement, un article qui est dans la file
- **THEN** l'article n'est plus dans la vue « Lire plus tard »

#### Scenario: Remettre en non lu
- **GIVEN** un article est sorti de la file en étant lu
- **WHEN** l'utilisateur le marque comme non lu
- **THEN** il revient dans la file, à sa place d'origine

### Requirement: Vue Lire plus tard
Le système SHALL proposer dans la barre latérale une entrée « Lire plus tard », sous « Aujourd'hui », indiquant le nombre d'articles de la file et listant ceux-ci du plus récemment ajouté au plus ancien.

#### Scenario: Consultation de la file
- **GIVEN** l'utilisateur a ajouté A puis B à la file
- **WHEN** il ouvre « Lire plus tard »
- **THEN** B est listé avant A, et l'entrée indique 2

#### Scenario: File vide
- **WHEN** la file est vide
- **THEN** l'entrée « Lire plus tard » reste affichée, sans nombre

### Requirement: Lire plus tard sur plusieurs articles
L'action SHALL porter sur toute la sélection : « Lire plus tard » ajoute à la file les articles qui n'y sont pas ; quand tous les articles sélectionnés sont dans la file, l'action devient « Retirer de Lire plus tard » et les en retire tous.

#### Scenario: Sélection mixte
- **GIVEN** trois articles sont sélectionnés, dont un déjà dans la file
- **WHEN** l'utilisateur choisit « Lire plus tard »
- **THEN** les trois sont dans la file

#### Scenario: Tous dans la file
- **GIVEN** deux articles de la file sont sélectionnés
- **WHEN** l'utilisateur choisit « Retirer de Lire plus tard »
- **THEN** aucun des deux n'est plus dans la file
