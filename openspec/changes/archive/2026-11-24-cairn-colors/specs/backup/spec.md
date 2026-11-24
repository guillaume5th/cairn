# Spec Delta

## MODIFIED Requirements

### Requirement: Contenu de la sauvegarde
Une sauvegarde SHALL être un fichier contenant les abonnements (titre, adresse, dossier, icône, options « Toujours charger les articles complets » et « Notifier les nouveaux articles »), les dossiers, les cairns avec leur couleur, tous les articles, gardés ou non, avec leur abonnement, leur état lu, leur présence dans la file « Lire plus tard », et pour les gardés leur cairn, leur note et leurs étiquettes, ainsi que leur résumé et leur texte complet, et les réglages de l'app. Elle MUST NOT contenir les résumés quotidiens ni l'état de l'interface.

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

#### Scenario: Couleur d'un cairn
- **GIVEN** le cairn « Pro » est bleu
- **WHEN** une sauvegarde est écrite puis restaurée
- **THEN** « Pro » est de nouveau bleu

#### Scenario: Sauvegarde antérieure aux couleurs
- **WHEN** l'utilisateur restaure une sauvegarde écrite avant l'existence des couleurs
- **THEN** la restauration réussit et ses cairns n'ont pas de couleur
