# Spec Delta

## ADDED Requirements

### Requirement: Marquer un abonnement ou un dossier comme lu
Le système SHALL proposer « Marquer tout comme lu » dans le menu contextuel d'un ou plusieurs abonnements et dans celui d'un dossier de la barre latérale. L'action MUST marquer comme lus tous les articles de ces abonnements, ou de tous les abonnements du dossier, sans changer l'entrée affichée. Elle MUST être grisée quand ils n'ont aucun article non lu.

#### Scenario: Abonnement avec des non lus
- **GIVEN** un abonnement a trois articles non lus
- **WHEN** l'utilisateur choisit « Marquer tout comme lu » dans son menu contextuel
- **THEN** ses trois articles sont lus et son compteur de non lus disparaît, ainsi que leur part dans les autres compteurs

#### Scenario: Dossier
- **GIVEN** un dossier contient deux abonnements ayant chacun des articles non lus
- **WHEN** l'utilisateur choisit « Marquer tout comme lu » dans le menu contextuel du dossier
- **THEN** tous les articles des deux abonnements sont lus

#### Scenario: Rien à marquer
- **WHEN** l'utilisateur ouvre le menu contextuel d'un abonnement sans article non lu
- **THEN** « Marquer tout comme lu » est grisé

### Requirement: Menu Article
Le système SHALL proposer dans la barre des menus un menu « Article » avec les mêmes actions, dans le même ordre, que le menu contextuel d'un article. Elles MUST porter sur l'article affiché ou sur les articles sélectionnés, et être grisées sans liste d'articles affichée. Garder MUST avoir le raccourci ⇧⌘L, Marquer comme lu ou non lu ⇧⌘U, et Ouvrir dans le navigateur ⌘↩.

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
