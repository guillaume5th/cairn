## MODIFIED Requirements

### Requirement: Barre d'outils du volet sans article
Le système SHALL, quand le volet de lecture n'affiche pas un article (aucun article sélectionné, sélection multiple ou mode sélection), garder les boutons de lecture à leur place, comme Mail. Avec au moins un article sélectionné, Garder, Marquer et Ouvrir dans le navigateur MUST être actifs et porter sur la sélection ; Partager MUST être actif pour un seul article sélectionné ; les autres boutons, dont l'inspecteur, sont grisés.

#### Scenario: Entrer en mode sélection
- **GIVEN** un article est affiché dans le volet de lecture
- **WHEN** l'utilisateur active le mode sélection
- **THEN** les boutons de lecture restent à leur place et ceux de la liste ne bougent pas

#### Scenario: Aucun article sélectionné
- **WHEN** le volet de lecture indique « Aucun article sélectionné »
- **THEN** les boutons Article complet, Résumer, Garder, Marquer, Partager, Ouvrir dans le navigateur et Inspecteur sont à leur place, tous grisés

#### Scenario: Actions d'une sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur regarde la barre d'outils du volet de lecture
- **THEN** Garder, Marquer comme lu et Ouvrir dans le navigateur sont actifs, et Article complet, Résumer, Partager et Inspecteur sont grisés

#### Scenario: Un seul article coché
- **GIVEN** le mode sélection est actif et un seul article est coché
- **WHEN** l'utilisateur choisit Partager dans la barre d'outils du volet de lecture
- **THEN** la feuille de partage s'ouvre avec le titre et le lien de cet article
