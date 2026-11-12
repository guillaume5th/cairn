# Proposal

## Why

Fermer la fenêtre de Cairn quitte l'application. Le résumé quotidien ne peut alors plus se produire à l'heure prévue, et rouvrir Cairn relance tout le démarrage. Sur Mac, l'usage attendu d'une app de ce type (comme Mail) est qu'elle reste active sans fenêtre et ne s'arrête que sur ⌘Q.

## What Changes

- Fermer la fenêtre principale ne quitte plus l'application : elle reste dans le Dock et continue de tourner.
- Cliquer sur l'icône du Dock (ou relancer l'app) rouvre la fenêtre principale.
- ⌘Q (Cairn > Quitter Cairn) quitte toujours l'application, en enregistrant les modifications en cours.
- Le travail de démarrage (préparation du cairn, purge, actualisation, programmation du résumé quotidien) ne s'exécute qu'une fois par lancement, même si la fenêtre est fermée puis rouverte.
- Le résumé quotidien est produit à l'heure réglée tant que l'app tourne, fenêtre ouverte ou non.
- Hors périmètre : icône dans la barre des menus, lancement à l'ouverture de session, actualisation automatique à la réouverture de la fenêtre.

## Capabilities

### New Capabilities
- `app-lifecycle` : cycle de vie de l'application — fermeture de la fenêtre, réouverture, sortie, démarrage unique.

### Modified Capabilities
- `daily-digest` : l'exigence « Heure du résumé quotidien » précise que le résumé est produit tant que l'app tourne, même sans fenêtre ouverte.

## Impact

- App : `CairnApp.swift` (délégué d'application qui garde l'app active à la fermeture de la dernière fenêtre), `AppState.swift` (`launch()` exécuté une seule fois).
- Aucune nouvelle dépendance, aucun changement de `CairnCore` ni des données.
