## ADDED Requirements

### Requirement: Citer un passage depuis le lecteur
Le système SHALL permettre, depuis le volet de lecture, d'ajouter le texte sélectionné dans l'article à la fin de sa note, en citation Markdown : chaque ligne préfixée par `> `, séparée du texte précédent par une ligne vide. L'action « Surligner » MUST être proposée dans le menu Édition, avec le raccourci ⇧⌘H, et dans la barre d'outils du lecteur. Sans texte sélectionné, elle MUST laisser la note inchangée.

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

#### Scenario: Depuis la barre d'outils
- **GIVEN** un article gardé est affiché
- **WHEN** l'utilisateur sélectionne un passage et clique le bouton « Surligner » de la barre d'outils
- **THEN** le passage est ajouté en citation à la fin de la note

#### Scenario: Barre d'outils sans article
- **WHEN** le volet de lecture n'affiche aucun article, ou plusieurs
- **THEN** le bouton « Surligner » est présent et grisé

### Requirement: Surbrillance des passages cités
Le système SHALL surligner dans l'article affiché chaque passage cité dans sa note (chaque bloc de lignes consécutives commençant par `> `), à sa première occurrence, d'une couleur distincte de celle de la recherche. La recherche MUST ignorer la casse, les accents et les différences d'espaces et de retours à la ligne, et trouver un passage qui traverse liens, mise en forme ou paragraphes. La surbrillance MUST suivre la note sans recharger l'article.

#### Scenario: Rouvrir un article cité
- **GIVEN** la note d'un article contient « > Le cache expire après 5 minutes »
- **WHEN** l'utilisateur ouvre l'article
- **THEN** « Le cache expire après 5 minutes » est surligné dans l'article

#### Scenario: Juste après la citation
- **WHEN** l'utilisateur sélectionne un passage et appuie sur ⇧⌘H
- **THEN** le passage est surligné dans l'article aussitôt

#### Scenario: Passage avec un lien ou sur deux paragraphes
- **GIVEN** la note cite un passage qui contient un lien et s'étend sur deux paragraphes de l'article
- **WHEN** l'utilisateur ouvre l'article
- **THEN** tout le passage est surligné, lien compris

#### Scenario: Citation effacée de la note
- **GIVEN** un passage cité est surligné dans l'article affiché
- **WHEN** l'utilisateur efface la citation de la note
- **THEN** le passage n'est plus surligné

#### Scenario: Citation introuvable
- **GIVEN** la note contient une citation modifiée à la main qui ne figure plus dans l'article
- **WHEN** l'utilisateur ouvre l'article
- **THEN** l'article s'affiche sans surbrillance pour cette citation, et les autres citations restent surlignées

#### Scenario: Avec la recherche
- **GIVEN** un passage cité est surligné et l'utilisateur cherche un mot qu'il contient
- **WHEN** puis il efface la recherche
- **THEN** le passage cité reste surligné

### Requirement: Indication dans la note vide
Le système SHALL afficher dans la note vide d'un article gardé une indication du geste de citation : « Sélectionnez un passage puis ⇧⌘H pour le citer ici ». L'indication MUST disparaître dès que la note contient du texte.

#### Scenario: Note vide
- **GIVEN** un article gardé sans note est affiché avec l'inspecteur
- **WHEN** l'utilisateur regarde la section Notes
- **THEN** elle affiche « Sélectionnez un passage puis ⇧⌘H pour le citer ici »

#### Scenario: Note remplie
- **WHEN** l'utilisateur tape un caractère dans la note vide
- **THEN** l'indication disparaît

## REMOVED Requirements

### Requirement: Citer un passage dans la note
**Reason**: Le passage cité reste désormais surligné dans l'article, ce que l'exigence interdisait (scénario « Pas de trace dans l'article ») ; OpenSpec ne permet pas de retirer un seul scénario.
**Migration**: Remplacée par « Citer un passage depuis le lecteur » (même comportement, plus le bouton de la barre d'outils) et « Surbrillance des passages cités ».
