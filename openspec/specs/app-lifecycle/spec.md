# app-lifecycle Specification

## Purpose

Définit comment Cairn démarre, reste actif et se termine : fermer la fenêtre ne quitte pas l'application, qui continue de tourner jusqu'à ce que l'utilisateur la quitte explicitement.

## Requirements

### Requirement: Fermer la fenêtre sans quitter
Le système SHALL continuer de tourner quand l'utilisateur ferme la fenêtre principale. L'application MUST rester présente dans le Dock.

#### Scenario: Fermeture de la fenêtre
- **WHEN** l'utilisateur ferme la fenêtre principale (⌘W ou bouton de fermeture)
- **THEN** la fenêtre disparaît et l'application reste active dans le Dock

### Requirement: Rouvrir la fenêtre
Le système SHALL rouvrir la fenêtre principale quand l'utilisateur clique sur l'icône du Dock ou relance l'application alors qu'aucune fenêtre n'est ouverte.

#### Scenario: Clic sur l'icône du Dock
- **GIVEN** l'application tourne sans fenêtre ouverte
- **WHEN** l'utilisateur clique sur l'icône de Cairn dans le Dock
- **THEN** la fenêtre principale s'affiche

### Requirement: Quitter l'application
Le système SHALL se terminer quand l'utilisateur choisit Quitter (⌘Q), en enregistrant les modifications en cours.

#### Scenario: Quitter avec ⌘Q
- **WHEN** l'utilisateur tape ⌘Q, fenêtre ouverte ou non
- **THEN** l'application se termine et la dernière modification est conservée au prochain lancement

### Requirement: Démarrage unique
Le système SHALL exécuter le travail de démarrage (préparation du cairn, purge, actualisation, programmation du résumé quotidien) une seule fois par lancement. Rouvrir la fenêtre MUST NOT le relancer.

#### Scenario: Réouverture de la fenêtre
- **GIVEN** l'application a démarré puis la fenêtre a été fermée
- **WHEN** l'utilisateur rouvre la fenêtre
- **THEN** aucune purge ni actualisation automatique n'est lancée, et un seul résumé automatique au plus est produit ce jour-là

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
