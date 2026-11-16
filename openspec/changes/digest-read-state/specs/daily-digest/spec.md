# Spec Delta

## ADDED Requirements

### Requirement: Résumés lus et non lus
Le système SHALL conserver pour chaque résumé quotidien un état lu ou non lu. Un résumé qui vient d'être produit MUST être non lu, et il devient lu dès qu'il est affiché seul dans le volet de lecture. La liste des résumés MUST signaler chaque résumé non lu par la même pastille que les articles non lus. Les résumés produits avant l'existence de cet état sont lus.

#### Scenario: Nouveau résumé
- **WHEN** un résumé est produit, automatiquement ou à la demande
- **THEN** il apparaît dans la liste avec la pastille des non lus

#### Scenario: Afficher un résumé
- **GIVEN** un résumé non lu
- **WHEN** l'utilisateur l'affiche dans le volet de lecture, depuis la liste ou depuis sa notification
- **THEN** il est lu et sa pastille disparaît

#### Scenario: Plusieurs résumés sélectionnés
- **GIVEN** deux résumés non lus
- **WHEN** l'utilisateur les sélectionne ensemble
- **THEN** ils restent non lus, puisque le volet n'affiche que leur nombre

#### Scenario: Résumés d'avant la mise à jour
- **GIVEN** des résumés produits avant la version qui introduit l'état lu / non lu
- **WHEN** l'utilisateur ouvre la liste des résumés après la mise à jour
- **THEN** aucun d'eux n'a la pastille des non lus

### Requirement: Changer l'état de lecture d'un résumé
Le système SHALL offrir « Marquer comme lu » ou « Marquer comme non lu » dans le menu contextuel de la liste des résumés, pour le résumé cliqué ou toute la sélection, et en balayant une ligne vers la droite, avec les mêmes libellés et symboles que pour les articles. Un résumé remis en non lu MUST le rester tant qu'il n'est pas affiché à nouveau.

#### Scenario: Remettre en non lu
- **GIVEN** le résumé affiché est lu
- **WHEN** l'utilisateur choisit « Marquer comme non lu » dans le menu contextuel de sa ligne
- **THEN** la pastille des non lus réapparaît sur sa ligne

#### Scenario: Marquer plusieurs résumés comme lus
- **GIVEN** trois résumés sélectionnés dont au moins un non lu
- **WHEN** l'utilisateur choisit « Marquer comme lu » dans le menu contextuel
- **THEN** les trois sont lus

#### Scenario: Balayer une ligne
- **GIVEN** un résumé non lu
- **WHEN** l'utilisateur balaie sa ligne vers la droite et choisit l'action proposée
- **THEN** le résumé est lu

### Requirement: Filtre des résumés non lus
Le système SHALL offrir dans la barre d'outils de la liste des résumés le même bouton « Non lus seulement » que la liste des articles, qui ne garde que les résumés non lus. Le résumé affiché MUST rester listé tant qu'un autre n'est pas choisi, même devenu lu, et le filtre MUST NOT faire marquer lu un autre résumé.

#### Scenario: Activer le filtre
- **GIVEN** deux résumés non lus et trois lus
- **WHEN** l'utilisateur active « Non lus seulement »
- **THEN** la liste montre les deux non lus, plus le résumé affiché s'il est lu

#### Scenario: Lire sous le filtre
- **GIVEN** le filtre est actif
- **WHEN** l'utilisateur affiche un résumé non lu
- **THEN** il devient lu et reste dans la liste, et les autres non lus restent non lus

### Requirement: Tout marquer comme lu
Le système SHALL offrir dans la barre d'outils de la liste des résumés le bouton « Tout marquer comme lu » de la liste des articles, qui marque lus tous les résumés listés.

#### Scenario: Tout marquer
- **GIVEN** trois résumés non lus
- **WHEN** l'utilisateur clique sur « Tout marquer comme lu »
- **THEN** les trois sont lus et l'entrée « Résumés quotidiens » n'affiche plus de nombre

### Requirement: Mode sélection des résumés
Le système SHALL offrir dans la barre d'outils de la liste des résumés le bouton « Sélectionner » de la liste des articles : un clic coche ou décoche un résumé, le titre de la liste donne le nombre de cochés, le volet de lecture affiche ce nombre, et Échap ou le même bouton quittent le mode sans rien changer.

#### Scenario: Cocher des résumés
- **GIVEN** le mode sélection est actif
- **WHEN** l'utilisateur clique sur deux résumés
- **THEN** ils sont cochés, le titre indique « 2 sélectionnés » et le volet de lecture « 2 résumés sélectionnés »

#### Scenario: Quitter le mode
- **WHEN** l'utilisateur appuie sur Échap en mode sélection
- **THEN** les coches disparaissent et aucun résumé n'est modifié

### Requirement: Actions du volet de lecture des résumés
Le système SHALL offrir dans la barre d'outils du volet de lecture des résumés, à côté de la corbeille, le bouton « Marquer comme lu / non lu » du lecteur d'articles. Il agit sur le résumé affiché ou sur tous les résumés sélectionnés, et il est grisé quand il n'y en a aucun.

#### Scenario: Remettre en non lu le résumé affiché
- **GIVEN** le résumé affiché est lu
- **WHEN** l'utilisateur clique sur « Marquer comme non lu » dans la barre d'outils du volet
- **THEN** sa ligne reprend la pastille des non lus et il reste affiché

#### Scenario: Plusieurs résumés
- **GIVEN** trois résumés sélectionnés dont un non lu
- **WHEN** l'utilisateur clique sur « Marquer comme lu » dans la barre d'outils du volet
- **THEN** les trois sont lus

### Requirement: Nombre de résumés non lus
Le système SHALL afficher dans la barre latérale, sur l'entrée « Résumés quotidiens », le nombre de résumés non lus, et aucun nombre quand tous sont lus.

#### Scenario: Un nouveau résumé
- **GIVEN** tous les résumés sont lus
- **WHEN** un résumé est produit
- **THEN** l'entrée « Résumés quotidiens » affiche 1

#### Scenario: Tous lus
- **WHEN** l'utilisateur affiche le dernier résumé non lu
- **THEN** l'entrée « Résumés quotidiens » n'affiche plus de nombre

## MODIFIED Requirements

### Requirement: Supprimer un résumé
Le système SHALL permettre de supprimer un résumé depuis la liste des résumés, par le bouton corbeille au-dessus du résumé affiché, son menu contextuel, la touche Supprimer ou en balayant sa ligne vers la gauche, après confirmation. La suppression MUST être définitive et ne touche ni les articles ni la date de la dernière tentative.

#### Scenario: Supprimer le résumé sélectionné
- **GIVEN** deux résumés sont listés et le plus récent est sélectionné
- **WHEN** l'utilisateur choisit « Supprimer le résumé… » puis confirme
- **THEN** ce résumé disparaît et l'autre s'affiche dans le volet de lecture

#### Scenario: Balayer une ligne vers la gauche
- **WHEN** l'utilisateur balaie la ligne d'un résumé vers la gauche, choisit la corbeille puis confirme
- **THEN** ce résumé disparaît, même s'il n'était pas sélectionné

#### Scenario: Annuler la suppression
- **WHEN** l'utilisateur annule la confirmation
- **THEN** le résumé reste

#### Scenario: Pas de nouveau résumé automatique
- **GIVEN** le résumé du jour a été produit puis supprimé
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun résumé automatique n'est relancé avant le lendemain
