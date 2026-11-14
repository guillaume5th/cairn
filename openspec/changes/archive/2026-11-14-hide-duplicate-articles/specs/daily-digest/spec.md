## ADDED Requirements

### Requirement: Un seul exemplaire par lien dans le résumé
Le système SHALL ne résumer et ne lister qu'un article par lien normalisé, même quand ce lien est arrivé par plusieurs abonnements dans les 24 heures.

#### Scenario: Article reçu deux fois
- **GIVEN** le même lien est arrivé par deux abonnements dans les 24 dernières heures
- **WHEN** le résumé est produit
- **THEN** l'article figure une seule fois dans le texte envoyé à l'IA et dans la liste qui suit le résumé
