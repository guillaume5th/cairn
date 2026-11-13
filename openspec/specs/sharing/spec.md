# sharing Specification

## Purpose
Permet d'envoyer un article de Cairn vers d'autres apps (Messages, Mail, Notes…) grâce au bouton Partager du système.

## Requirements

### Requirement: Partager un article
Le système SHALL proposer une action « Partager » dans la barre d'outils du panneau de lecture et dans le menu contextuel d'un article. Elle ouvre la feuille de partage du système avec le titre et le lien de l'article. L'action MUST être indisponible pour un article sans lien http ou https.

#### Scenario: Envoyer un article par Messages
- **WHEN** l'utilisateur choisit « Partager » sur un article, puis Messages
- **THEN** un message est préparé avec le titre et le lien de l'article

#### Scenario: Article sans lien web
- **WHEN** l'article n'a pas de lien http ou https
- **THEN** l'action « Partager » est indisponible

### Requirement: Copier le lien
Le système SHALL proposer « Copier le lien » dans le menu contextuel d'un article et dans le menu « Article ». L'action MUST placer le lien web de l'article dans le presse-papiers ; pour plusieurs articles, elle s'intitule « Copier les liens » et place un lien par ligne. Elle MUST être grisée quand aucun article n'a de lien http ou https.

#### Scenario: Un article
- **WHEN** l'utilisateur choisit « Copier le lien » sur un article
- **THEN** le presse-papiers contient le lien de cet article

#### Scenario: Plusieurs articles
- **GIVEN** trois articles avec un lien web sont sélectionnés
- **WHEN** l'utilisateur choisit « Copier les liens »
- **THEN** le presse-papiers contient leurs trois liens, un par ligne
