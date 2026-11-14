# Spec Delta

## MODIFIED Requirements

### Requirement: Purger les articles non gardés
Le système SHALL supprimer automatiquement, au lancement, les articles non gardés dont la date de publication dépasse la durée de conservation réglée (« Conserver les articles non gardés » : 7, 14 ou 30 jours, 2, 3 ou 6 mois, 1 an ; 30 jours par défaut). Les articles gardés et les articles non lus de la file « Lire plus tard » MUST NOT être purgés.

#### Scenario: Article ancien non gardé
- **GIVEN** la durée de conservation est de 30 jours
- **WHEN** l'application démarre et qu'un article non gardé a plus de 30 jours
- **THEN** cet article est supprimé

#### Scenario: Article ancien gardé
- **WHEN** l'application démarre et qu'un article gardé dépasse la durée de conservation
- **THEN** cet article est conservé

#### Scenario: Durée allongée
- **GIVEN** la durée de conservation est de 3 mois
- **WHEN** l'application démarre et qu'un article non gardé a 45 jours
- **THEN** cet article est conservé

#### Scenario: Article ancien dans la file
- **GIVEN** la durée de conservation est de 30 jours
- **WHEN** l'application démarre et qu'un article non lu de la file « Lire plus tard » a plus de 30 jours
- **THEN** cet article est conservé

### Requirement: Menu Article
Le système SHALL proposer dans la barre des menus un menu « Article » avec les mêmes actions, dans le même ordre, que le menu contextuel d'un article. Elles MUST porter sur l'article affiché ou sur les articles sélectionnés, et être grisées sans liste d'articles affichée. Garder MUST avoir le raccourci ⇧⌘L, Lire plus tard ⇧⌘D, Marquer comme lu ou non lu ⇧⌘U, et Ouvrir dans le navigateur ⌘↩.

#### Scenario: Basculer au clavier
- **GIVEN** un article lu est affiché
- **WHEN** l'utilisateur appuie sur ⇧⌘U, puis de nouveau sur ⇧⌘U
- **THEN** l'article redevient non lu, puis de nouveau lu

#### Scenario: Sélection multiple
- **GIVEN** trois articles non lus sont sélectionnés
- **WHEN** l'utilisateur choisit Article > Marquer comme lu
- **THEN** les trois articles sont lus

#### Scenario: Pas de liste d'articles
- **WHEN** « Résumés quotidiens » est affiché
- **THEN** les actions du menu « Article » sont grisées

#### Scenario: Lire plus tard au clavier
- **GIVEN** un article non lu est affiché
- **WHEN** l'utilisateur appuie sur ⇧⌘D
- **THEN** l'article est ajouté à la file « Lire plus tard »
