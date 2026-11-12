# Spec Delta

## ADDED Requirements

### Requirement: Mode sélection
Le système SHALL proposer dans la barre d'outils de la liste d'articles un bouton « Sélectionner » qui passe la liste en mode sélection : chaque ligne montre une case, et un clic ou un toucher sur une ligne l'ajoute à la sélection ou l'en retire. Sur Mac, ⌘-clic et ⇧-clic restent disponibles et passent aussi en mode sélection dès que plusieurs articles sont sélectionnés. Quitter le mode (bouton ou Échap) MUST vider la sélection.

#### Scenario: Cocher des articles
- **GIVEN** l'utilisateur a activé le mode sélection
- **WHEN** il clique sur deux articles puis de nouveau sur le premier
- **THEN** seul le second article est sélectionné et coché

#### Scenario: Quitter sans action
- **GIVEN** trois articles sont cochés en mode sélection
- **WHEN** l'utilisateur touche de nouveau « Sélectionner » ou appuie sur Échap
- **THEN** le mode sélection se termine et aucun article ne reste sélectionné

### Requirement: Titre et actions d'une sélection
Le système SHALL, en mode sélection sur Mac et sur iPhone, remplacer le titre de la liste par le nombre d'articles sélectionnés (« Aucune sélection », « 1 sélectionné », « N sélectionnés ») et afficher sous la liste les actions qui s'appliquent à la sélection : garder dans un cairn, marquer comme lu ou non lu, ouvrir dans le navigateur, et supprimer quand tous les articles sélectionnés n'ont plus d'abonnement. Sans article sélectionné, ces actions MUST être inactives.

#### Scenario: Trois articles cochés sur Mac
- **WHEN** l'utilisateur coche trois articles en mode sélection
- **THEN** le titre de la liste devient « 3 sélectionnés » et les actions apparaissent sous la liste

#### Scenario: Aucune sélection
- **WHEN** l'utilisateur active le mode sélection sans cocher d'article
- **THEN** le titre affiche « Aucune sélection » et les actions sous la liste sont inactives

## MODIFIED Requirements

### Requirement: Volet de lecture d'une sélection multiple
Le système SHALL, quand plusieurs articles sont sélectionnés, afficher dans le volet de lecture le nombre d'articles sélectionnés (« N articles sélectionnés ») au lieu d'un article. Sur iPad, le volet de lecture porte aussi les actions qui s'appliquent à toute la sélection ; sur Mac, elles sont sous la liste.

#### Scenario: Plusieurs articles sélectionnés
- **WHEN** l'utilisateur sélectionne trois articles
- **THEN** le volet de lecture affiche « 3 articles sélectionnés », et les actions sur la sélection sont proposées sous la liste (Mac) ou dans le volet (iPad)

#### Scenario: Retour à un seul article
- **GIVEN** trois articles sont sélectionnés au ⌘-clic, hors du mode sélection
- **WHEN** l'utilisateur clique sur un seul article sans touche de modification
- **THEN** cet article est affiché comme d'habitude
