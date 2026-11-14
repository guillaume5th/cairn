# app-updates Specification

## Purpose

Garder Cairn à jour sans réinstallation manuelle, grâce à Sparkle et aux releases GitHub.

## Requirements

### Requirement: Rechercher les mises à jour
Le système SHALL vérifier automatiquement, une fois par jour, si une version plus récente de Cairn est publiée, et MUST proposer « Rechercher les mises à jour… » dans le menu Cairn pour vérifier aussitôt. Une version plus récente SHALL être proposée à l'installation, puis Cairn redémarre sur cette version. Cairn Dev MUST NOT rechercher de mises à jour.

#### Scenario: Nouvelle version publiée
- **GIVEN** la version 2.3.0 est installée et la 2.4.0 est publiée
- **WHEN** l'utilisateur choisit « Rechercher les mises à jour… »
- **THEN** Cairn propose d'installer la 2.4.0

#### Scenario: Déjà à jour
- **WHEN** l'utilisateur recherche les mises à jour alors que la dernière version est installée
- **THEN** Cairn indique qu'il est à jour

### Requirement: Mises à jour signées
Le système MUST n'installer qu'une mise à jour dont la signature EdDSA correspond à la clé publique intégrée à l'app. Chaque release SHALL publier, avec son DMG signé, un appcast décrivant cette version.

#### Scenario: Archive altérée
- **WHEN** le DMG téléchargé ne correspond pas à sa signature
- **THEN** la mise à jour est refusée et l'app installée reste inchangée
