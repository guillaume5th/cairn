# Spec Delta

## ADDED Requirements

### Requirement: Sélection d'article par défaut
Quand une entrée de la barre latérale (« Tous les articles », « Cairn », un tag ou un abonnement) est affichée sans article mémorisé visible dans sa liste, le système SHALL sélectionner et afficher le premier article de la liste. Si la liste est vide, aucun article n'est sélectionné.

#### Scenario: Premier lancement
- **WHEN** l'utilisateur lance l'app pour la première fois et que « Tous les articles » contient des articles
- **THEN** le premier article de la liste est sélectionné et affiché dans le panneau de lecture

#### Scenario: Entrée jamais ouverte
- **WHEN** l'utilisateur sélectionne un abonnement dont aucun article n'a encore été sélectionné
- **THEN** le premier article de cet abonnement est sélectionné et affiché

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
- **THEN** le premier article de la liste est sélectionné

### Requirement: Sélection conservée entre les lancements
Le système SHALL conserver d'un lancement à l'autre l'entrée de la barre latérale affichée et l'article mémorisé de chaque entrée. Cette mémoire est propre à l'appareil.

#### Scenario: Relancement
- **GIVEN** l'utilisateur lisait l'article A de l'abonnement X
- **WHEN** il quitte puis relance l'app
- **THEN** l'abonnement X est affiché avec l'article A sélectionné

#### Scenario: Entrée disparue
- **GIVEN** l'entrée affichée au moment de quitter n'existe plus au relancement (abonnement supprimé, tag disparu)
- **WHEN** l'utilisateur relance l'app
- **THEN** « Tous les articles » est affiché

## MODIFIED Requirements

### Requirement: État lu / non lu
Le système SHALL marquer un article comme lu quand l'utilisateur le sélectionne lui-même (clic ou clavier), et MUST permettre de le remettre manuellement en non lu ou de marquer tous les articles de la liste courante comme lus. Un article sélectionné automatiquement (sélection par défaut ou mémorisée) MUST être affiché sans que son état lu change.

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
