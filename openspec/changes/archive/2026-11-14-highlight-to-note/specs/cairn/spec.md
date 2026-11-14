## ADDED Requirements

### Requirement: Citer un passage dans la note
Le système SHALL permettre, depuis le volet de lecture, d'ajouter le texte sélectionné dans l'article à la fin de sa note, en citation Markdown : chaque ligne préfixée par `> `, séparée du texte précédent par une ligne vide. L'action « Surligner » MUST être proposée dans le menu Édition, avec le raccourci ⇧⌘H. Sans texte sélectionné, elle MUST laisser la note inchangée. Le passage MUST NOT rester surligné dans l'article.

#### Scenario: Citer dans un article gardé
- **GIVEN** un article gardé a la note « À relire »
- **WHEN** l'utilisateur sélectionne « Le cache expire après 5 minutes » dans l'article et appuie sur ⇧⌘H
- **THEN** la note devient « À relire », une ligne vide, puis « > Le cache expire après 5 minutes »

#### Scenario: Passage sur plusieurs paragraphes
- **WHEN** l'utilisateur cite un passage de deux paragraphes
- **THEN** chaque ligne du passage commence par `> ` dans la note
#### Scenario: Aucune sélection
- **WHEN** aucun texte n'est sélectionné dans un article gardé et l'utilisateur appuie sur ⇧⌘H
- **THEN** la note est inchangée

#### Scenario: Pas de trace dans l'article
- **WHEN** l'utilisateur cite un passage puis rouvre l'article
- **THEN** le passage n'est pas surligné dans l'article

### Requirement: Citer dans un article non gardé
Le système SHALL garder d'abord un article non gardé avant d'y citer un passage, selon la règle de « Garder un article » : sans choix quand il n'existe qu'un cairn ; sinon l'action devient « Surligner dans » et propose les cairns, et ⇧⌘H MUST être sans effet.

#### Scenario: Article non gardé, un seul cairn
- **GIVEN** il n'existe qu'un cairn et l'article affiché n'est pas gardé
- **WHEN** l'utilisateur sélectionne un passage et choisit « Surligner »
- **THEN** l'article est gardé dans ce cairn et sa note contient le passage cité

#### Scenario: Article non gardé, plusieurs cairns
- **GIVEN** il existe les cairns « Perso » et « Pro » et l'article affiché n'est pas gardé
- **WHEN** l'utilisateur sélectionne un passage et choisit « Surligner dans » puis « Pro »
- **THEN** l'article est gardé dans « Pro » et sa note contient le passage cité

#### Scenario: Raccourci, plusieurs cairns
- **GIVEN** il existe plusieurs cairns et l'article affiché n'est pas gardé
- **WHEN** l'utilisateur sélectionne un passage et appuie sur ⇧⌘H
- **THEN** l'article n'est pas gardé et aucune note n'est créée
