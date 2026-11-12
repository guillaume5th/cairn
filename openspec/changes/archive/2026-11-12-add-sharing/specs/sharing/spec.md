# Spec Delta

## Purpose

Permet d'envoyer un article de Cairn vers d'autres apps (Messages, Mail, Notes…) grâce au bouton Partager du système.

## ADDED Requirements

### Requirement: Partager un article
Le système SHALL proposer une action « Partager » dans la barre d'outils du panneau de lecture et dans le menu contextuel d'un article. Elle ouvre la feuille de partage du système avec le titre et le lien de l'article. L'action MUST être indisponible pour un article sans lien http ou https.

#### Scenario: Envoyer un article par Messages
- **WHEN** l'utilisateur choisit « Partager » sur un article, puis Messages
- **THEN** un message est préparé avec le titre et le lien de l'article

#### Scenario: Article sans lien web
- **WHEN** l'article n'a pas de lien http ou https
- **THEN** l'action « Partager » est indisponible
