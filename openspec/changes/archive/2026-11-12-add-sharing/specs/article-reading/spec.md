# Spec Delta

## MODIFIED Requirements

### Requirement: Barre d'outils du volet sans article
Le système SHALL, quand le volet de lecture n'affiche pas un article (aucun article sélectionné, sélection multiple ou mode sélection), y garder les boutons de lecture grisés, comme Mail, pour que la barre d'outils ne change pas de disposition. Ces boutons sont : Résumer, Garder, Marquer comme non lu, Partager et Ouvrir dans le navigateur.

#### Scenario: Entrer en mode sélection
- **GIVEN** un article est affiché dans le volet de lecture
- **WHEN** l'utilisateur active le mode sélection
- **THEN** les boutons de lecture restent à leur place, grisés, et ceux de la liste ne bougent pas
