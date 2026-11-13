# Spec Delta

## ADDED Requirements

### Requirement: Copier le lien
Le système SHALL proposer « Copier le lien » dans le menu contextuel d'un article et dans le menu « Article ». L'action MUST placer le lien web de l'article dans le presse-papiers ; pour plusieurs articles, elle s'intitule « Copier les liens » et place un lien par ligne. Elle MUST être grisée quand aucun article n'a de lien http ou https.

#### Scenario: Un article
- **WHEN** l'utilisateur choisit « Copier le lien » sur un article
- **THEN** le presse-papiers contient le lien de cet article

#### Scenario: Plusieurs articles
- **GIVEN** trois articles avec un lien web sont sélectionnés
- **WHEN** l'utilisateur choisit « Copier les liens »
- **THEN** le presse-papiers contient leurs trois liens, un par ligne
