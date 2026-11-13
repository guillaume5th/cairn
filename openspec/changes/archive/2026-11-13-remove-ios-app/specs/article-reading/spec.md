# Spec Delta

## MODIFIED Requirements

### Requirement: Titre et actions d'une sélection
Le système SHALL, en mode sélection, remplacer le titre de la liste par le nombre d'articles sélectionnés (« Aucune sélection », « 1 sélectionné », « N sélectionnés ») et afficher sous la liste les actions qui s'appliquent à la sélection : garder dans un cairn, marquer comme lu ou non lu, ouvrir dans le navigateur, et supprimer quand tous les articles sélectionnés n'ont plus d'abonnement. Sans article sélectionné, ces actions MUST être inactives.

#### Scenario: Trois articles cochés
- **WHEN** l'utilisateur coche trois articles en mode sélection
- **THEN** le titre de la liste devient « 3 sélectionnés » et les actions apparaissent sous la liste

#### Scenario: Aucune sélection
- **WHEN** l'utilisateur active le mode sélection sans cocher d'article
- **THEN** le titre affiche « Aucune sélection » et les actions sous la liste sont inactives
