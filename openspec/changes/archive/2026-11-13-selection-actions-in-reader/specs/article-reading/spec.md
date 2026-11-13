# Spec Delta

## MODIFIED Requirements

### Requirement: Volet de lecture d'une sélection multiple
Le système SHALL, quand plusieurs articles sont sélectionnés ou en mode sélection, afficher dans le volet de lecture le nombre d'articles sélectionnés (« N articles sélectionnés ») au lieu d'un article. Les actions sur la sélection MUST être dans la barre d'outils du volet de lecture, aux mêmes places que pour un seul article, et aucune barre d'actions ne s'affiche sous la liste.

#### Scenario: Plusieurs articles sélectionnés
- **WHEN** l'utilisateur sélectionne trois articles
- **THEN** le volet de lecture affiche « 3 articles sélectionnés », les actions sur la sélection sont actives dans sa barre d'outils, et rien ne recouvre la liste

#### Scenario: Retour à un seul article
- **GIVEN** trois articles sont sélectionnés au ⌘-clic, hors du mode sélection
- **WHEN** l'utilisateur clique sur un seul article sans touche de modification
- **THEN** cet article est affiché comme d'habitude

### Requirement: Barre d'outils du volet sans article
Le système SHALL, quand le volet de lecture n'affiche pas un article (aucun article sélectionné, sélection multiple ou mode sélection), y garder les boutons de lecture à leur place, comme Mail, pour que la barre d'outils ne change pas de disposition. Avec au moins un article sélectionné, Garder, Marquer et Ouvrir dans le navigateur MUST être actifs et porter sur la sélection ; les autres boutons sont grisés.

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

### Requirement: Titre et actions d'une sélection
Le système SHALL, en mode sélection, remplacer le titre de la liste par le nombre d'articles sélectionnés (« Aucune sélection », « 1 sélectionné », « N sélectionnés ») et proposer les actions sur la sélection dans la barre d'outils du volet de lecture. La suppression d'articles qui n'ont plus d'abonnement MUST rester disponible par le menu contextuel et la touche Supprimer. Sans article sélectionné, ces actions MUST être inactives.

#### Scenario: Trois articles cochés
- **WHEN** l'utilisateur coche trois articles en mode sélection
- **THEN** le titre de la liste devient « 3 sélectionnés » et les actions sont actives dans la barre d'outils du volet de lecture

#### Scenario: Aucune sélection
- **WHEN** l'utilisateur active le mode sélection sans cocher d'article
- **THEN** le titre affiche « Aucune sélection » et les actions du volet de lecture sont inactives

#### Scenario: Supprimer des articles sans abonnement
- **GIVEN** deux articles dont l'abonnement a été supprimé sont cochés
- **WHEN** l'utilisateur appuie sur la touche Supprimer ou choisit « Supprimer 2 articles… » dans le menu contextuel
- **THEN** le système demande confirmation avant de les supprimer
