# Spec Delta

## ADDED Requirements

### Requirement: Reprendre les données de l'ancienne version sandboxée
Le système SHALL, au premier lancement d'une version hors sandbox, reprendre les articles, abonnements, cairns, résumés, réglages et le dossier de sauvegarde de la version sandboxée, s'il n'a pas encore de données à lui. Les données de l'ancien conteneur MUST NOT être supprimées ni modifiées.

#### Scenario: Mise à jour depuis une version sandboxée
- **GIVEN** l'utilisateur a des articles, des cairns et des réglages dans une version sandboxée de Cairn
- **WHEN** il lance pour la première fois une version hors sandbox
- **THEN** il retrouve ses articles, ses cairns, ses résumés, ses réglages et son dossier de sauvegarde

#### Scenario: Ancien conteneur intact
- **WHEN** les données ont été reprises
- **THEN** l'ancien conteneur est toujours présent et inchangé

#### Scenario: Pas de reprise en double
- **GIVEN** la version hors sandbox a déjà ses propres données
- **WHEN** l'utilisateur relance Cairn
- **THEN** rien n'est recopié depuis l'ancien conteneur

#### Scenario: Nouvelle installation
- **GIVEN** aucun ancien conteneur n'existe
- **WHEN** l'utilisateur lance Cairn pour la première fois
- **THEN** Cairn démarre avec une base vide, sans erreur
