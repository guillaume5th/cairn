## MODIFIED Requirements

### Requirement: Contenu de la sauvegarde
Une sauvegarde SHALL être un fichier contenant les abonnements (titre, adresse, dossier, icône, options « Toujours charger les articles complets » et « Notifier les nouveaux articles »), les dossiers, les cairns, tous les articles, gardés ou non, avec leur abonnement, leur état lu, et pour les gardés leur cairn, leur note et leurs étiquettes, ainsi que leur résumé et leur texte complet, et les réglages de l'app. Elle MUST NOT contenir les résumés quotidiens ni l'état de l'interface.

#### Scenario: Article gardé avec note et étiquettes
- **GIVEN** un article gardé dans le cairn « Lectures », avec une note et l'étiquette « swift »
- **WHEN** une sauvegarde est écrite
- **THEN** le fichier contient cet article avec son cairn, sa note et son étiquette

#### Scenario: Article non gardé
- **GIVEN** un article non gardé déjà lu
- **WHEN** une sauvegarde est écrite
- **THEN** le fichier contient cet article, marqué comme lu
