## ADDED Requirements

### Requirement: Classer les abonnements dans des dossiers
Le système SHALL permettre de créer des dossiers nommés et d'y ranger les abonnements, sur un seul niveau. Un abonnement MUST être dans au plus un dossier ; les abonnements sans dossier restent à la racine. Deux dossiers MUST NOT porter le même nom (casse et accents ignorés). Chaque dossier MUST afficher le total des articles non lus de ses abonnements.

#### Scenario: Créer un dossier
- **WHEN** l'utilisateur choisit « Nouveau dossier… » et saisit « Swift »
- **THEN** un dossier « Swift » vide apparaît dans la section Abonnements

#### Scenario: Nom déjà pris
- **WHEN** l'utilisateur crée ou renomme un dossier avec le nom « swift » alors qu'un dossier « Swift » existe
- **THEN** aucun dossier n'est créé ni renommé et l'utilisateur en est informé

#### Scenario: Ranger par glisser-déposer
- **WHEN** l'utilisateur fait glisser un abonnement sur le dossier « Swift »
- **THEN** l'abonnement apparaît dans « Swift » et n'est plus à la racine ni dans son ancien dossier

#### Scenario: Ranger par le menu contextuel
- **WHEN** l'utilisateur choisit « Déplacer vers » > « Aucun dossier » sur un abonnement rangé
- **THEN** l'abonnement revient à la racine de la section Abonnements

#### Scenario: Compteur du dossier
- **WHEN** le dossier « Swift » contient deux abonnements avec 3 et 4 articles non lus
- **THEN** le dossier affiche 7

#### Scenario: Replier un dossier
- **WHEN** l'utilisateur replie le dossier « Swift »
- **THEN** ses abonnements sont masqués dans la barre latérale et son compteur reste visible

### Requirement: Renommer et supprimer un dossier
Le système SHALL permettre de renommer un dossier et de le supprimer. La suppression d'un dossier MUST conserver ses abonnements et leurs articles, qui reviennent à la racine.

#### Scenario: Renommer
- **WHEN** l'utilisateur renomme le dossier « Swift » en « Apple »
- **THEN** le dossier s'appelle « Apple » et garde ses abonnements

#### Scenario: Supprimer
- **WHEN** l'utilisateur supprime un dossier contenant deux abonnements
- **THEN** le dossier disparaît, les deux abonnements sont à la racine avec tous leurs articles

## MODIFIED Requirements

### Requirement: Importer un fichier OPML
Le système SHALL permettre d'importer un fichier OPML et de créer un abonnement pour chaque flux qu'il contient, y compris les flux imbriqués dans des dossiers. Chaque nouvel abonnement MUST être rangé dans le dossier de premier niveau qui le contient, créé s'il n'existe pas (même nom, casse et accents ignorés) ; les sous-dossiers sont fusionnés dans ce dossier. Les flux déjà suivis MUST être ignorés et garder leur dossier actuel.

#### Scenario: Import d'un OPML avec dossiers
- **WHEN** l'utilisateur importe un OPML contenant des flux répartis dans des dossiers
- **THEN** un abonnement est créé pour chaque flux, rangé dans un dossier du même nom que son dossier de premier niveau

#### Scenario: Sous-dossier
- **WHEN** l'OPML contient un flux dans le dossier « Inner », lui-même dans le dossier « Swift »
- **THEN** l'abonnement est rangé dans le dossier « Swift »

#### Scenario: Dossier existant
- **WHEN** l'OPML contient un dossier « swift » et qu'un dossier « Swift » existe déjà
- **THEN** les nouveaux abonnements sont rangés dans « Swift » et aucun dossier n'est ajouté

#### Scenario: Réimport du même fichier
- **WHEN** l'utilisateur importe un OPML dont tous les flux sont déjà suivis
- **THEN** aucun abonnement n'est ajouté, aucun abonnement ne change de dossier et l'utilisateur voit le nombre de flux ignorés

#### Scenario: Fichier OPML illisible
- **WHEN** l'utilisateur importe un fichier qui n'est pas un OPML valide
- **THEN** aucun abonnement n'est créé et un message d'erreur est affiché

### Requirement: Exporter les abonnements en OPML
Le système SHALL permettre d'exporter tous les abonnements dans un fichier OPML 2.0 que l'utilisateur enregistre où il le souhaite. Chaque flux MUST y figurer avec son nom et son URL, à l'intérieur de son dossier s'il en a un.

#### Scenario: Export puis réimport
- **WHEN** l'utilisateur exporte ses abonnements puis réimporte le fichier dans une base vide
- **THEN** les mêmes abonnements sont recréés, dans les mêmes dossiers
