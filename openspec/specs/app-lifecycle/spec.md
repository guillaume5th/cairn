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
