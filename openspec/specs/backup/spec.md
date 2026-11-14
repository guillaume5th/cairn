# backup Specification

## Purpose

Protège les abonnements, les articles, les cairns et les réglages de Cairn par une sauvegarde quotidienne dans un dossier choisi par l'utilisateur, par exemple dans iCloud Drive, et permet de les restaurer en cas de problème.

## Requirements

### Requirement: Choisir le dossier de sauvegarde
Le système SHALL proposer dans une section « Sauvegarde » des Réglages le choix d'un dossier de sauvegarde, par la fenêtre de choix de dossier du système. L'accès à ce dossier MUST être conservé entre les lancements. Sans dossier choisi, aucune sauvegarde automatique n'a lieu.

#### Scenario: Choisir un dossier dans iCloud Drive
- **WHEN** l'utilisateur choisit le dossier « Cairn » de son iCloud Drive
- **THEN** les Réglages affichent ce dossier, et une sauvegarde y est écrite aussitôt

#### Scenario: Aucun dossier choisi
- **WHEN** aucun dossier de sauvegarde n'a été choisi
- **THEN** aucune sauvegarde n'est écrite, et les Réglages indiquent que la sauvegarde automatique est inactive

#### Scenario: Dossier devenu inaccessible
- **GIVEN** le dossier choisi a été supprimé ou son accès a été perdu
- **WHEN** une sauvegarde est due
- **THEN** aucune sauvegarde n'est écrite et les Réglages affichent l'erreur avec la possibilité de choisir à nouveau le dossier

### Requirement: Contenu de la sauvegarde
Une sauvegarde SHALL être un fichier contenant les abonnements (titre, adresse, dossier, icône, options « Toujours charger les articles complets » et « Notifier les nouveaux articles »), les dossiers, les cairns, tous les articles, gardés ou non, avec leur abonnement, leur état lu, leur présence dans la file « Lire plus tard », et pour les gardés leur cairn, leur note et leurs étiquettes, ainsi que leur résumé et leur texte complet, et les réglages de l'app. Elle MUST NOT contenir les résumés quotidiens ni l'état de l'interface.

#### Scenario: Article gardé avec note et étiquettes
- **GIVEN** un article gardé dans le cairn « Lectures », avec une note et l'étiquette « swift »
- **WHEN** une sauvegarde est écrite
- **THEN** le fichier contient cet article avec son cairn, sa note et son étiquette

#### Scenario: Article non gardé
- **GIVEN** un article non gardé déjà lu
- **WHEN** une sauvegarde est écrite
- **THEN** le fichier contient cet article, marqué comme lu

#### Scenario: Article dans la file
- **GIVEN** un article est dans la file « Lire plus tard »
- **WHEN** une sauvegarde est écrite puis restaurée
- **THEN** l'article est de nouveau dans la file, à sa place

### Requirement: Sauvegarde quotidienne
Le système SHALL écrire une sauvegarde dans le dossier choisi quand la dernière date de plus de 24 heures, au lancement et tant que l'application tourne, fenêtre ouverte ou fermée. Le système SHALL aussi proposer « Sauvegarder maintenant ». Un fichier n'est jamais laissé à moitié écrit.

#### Scenario: Lancement après plus d'un jour
- **GIVEN** la dernière sauvegarde date de 30 heures
- **WHEN** l'utilisateur lance l'application
- **THEN** une sauvegarde est écrite dans le dossier choisi

#### Scenario: Application ouverte en continu
- **WHEN** l'application reste ouverte et que 24 heures passent depuis la dernière sauvegarde
- **THEN** une nouvelle sauvegarde est écrite

#### Scenario: Sauvegarder maintenant
- **WHEN** l'utilisateur choisit « Sauvegarder maintenant »
- **THEN** une sauvegarde est écrite aussitôt et les Réglages affichent sa date

### Requirement: Conserver sept sauvegardes
Le système SHALL garder dans le dossier les 7 sauvegardes de Cairn les plus récentes et supprimer les plus anciennes après chaque sauvegarde réussie. Les autres fichiers du dossier MUST NOT être touchés.

#### Scenario: Huitième sauvegarde
- **GIVEN** le dossier contient 7 sauvegardes de Cairn et un autre fichier
- **WHEN** une nouvelle sauvegarde est écrite
- **THEN** la plus ancienne sauvegarde est supprimée, et l'autre fichier reste

### Requirement: Restaurer une sauvegarde
Le système SHALL proposer « Restaurer… » dans la section Sauvegarde des Réglages. Après le choix d'un fichier et une confirmation qui annonce le remplacement, les abonnements, dossiers, cairns, articles et réglages MUST être remplacés par ceux de la sauvegarde, dans leur état au moment de la sauvegarde, puis les flux sont rafraîchis. Les résumés quotidiens sont conservés. Un fichier illisible MUST ne rien modifier.

#### Scenario: Restauration sur une installation vide
- **GIVEN** une installation neuve, sans abonnement
- **WHEN** l'utilisateur restaure une sauvegarde et confirme
- **THEN** les abonnements avec leurs icônes, dossiers, cairns, articles et réglages de la sauvegarde sont présents, et les articles publiés depuis arrivent avec le rafraîchissement

#### Scenario: État lu des articles non gardés
- **GIVEN** une sauvegarde où un article non gardé est lu et un autre non lu
- **WHEN** l'utilisateur la restaure
- **THEN** le premier est lu et le second non lu, comme au moment de la sauvegarde

#### Scenario: Restauration remplace l'existant
- **GIVEN** un abonnement absent de la sauvegarde
- **WHEN** l'utilisateur restaure la sauvegarde et confirme
- **THEN** cet abonnement n'existe plus

#### Scenario: Annuler
- **WHEN** l'utilisateur annule la confirmation
- **THEN** rien ne change

#### Scenario: Fichier illisible
- **WHEN** l'utilisateur choisit un fichier qui n'est pas une sauvegarde de Cairn
- **THEN** une erreur s'affiche et aucune donnée n'est modifiée

#### Scenario: Pas de doublon au rafraîchissement
- **GIVEN** la sauvegarde contient des articles, gardés ou non, d'un abonnement qu'elle contient aussi
- **WHEN** la restauration est suivie du rafraîchissement de cet abonnement
- **THEN** chaque article n'apparaît qu'une fois et garde l'état restauré
