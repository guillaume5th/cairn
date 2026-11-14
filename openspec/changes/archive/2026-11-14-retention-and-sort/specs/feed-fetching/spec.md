## MODIFIED Requirements

### Requirement: Ignorer les articles déjà expirés
Le système MUST NOT réimporter un article dont la date de publication dépasse la durée de conservation réglée des articles non gardés.

#### Scenario: Ancien article toujours présent dans le flux
- **GIVEN** la durée de conservation est de 30 jours
- **WHEN** un flux contient un article publié il y a plus de 30 jours et absent de la base
- **THEN** cet article n'est pas ajouté
