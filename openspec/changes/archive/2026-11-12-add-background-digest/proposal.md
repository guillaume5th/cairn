# Proposal

## Why

Sur iPhone et iPad, le résumé quotidien n'est produit que si Cairn est à l'écran : le matin, il faut ouvrir l'app puis attendre le rafraîchissement et le moteur d'IA. Sur Mac, le résumé se fait bien en tâche de fond, mais rien ne prévient qu'il est prêt. Un résumé quotidien n'est utile que s'il arrive de lui-même.

## What Changes

- iOS : rafraîchissement des abonnements en arrière-plan, quand le système le permet, pour que la liste soit à jour à l'ouverture.
- iOS : production du résumé quotidien en arrière-plan à l'heure réglée (au mieux : c'est iOS qui décide du moment exact). Si le moteur ne peut pas travailler en arrière-plan, le résumé est fait au retour dans l'app, comme aujourd'hui.
- Mac et iOS : notification « Ton résumé du jour est prêt » quand un résumé automatique est produit alors que Cairn n'est pas au premier plan ; la toucher ouvre ce résumé.
- Réglage « Me prévenir quand le résumé est prêt » dans la section Résumé quotidien, désactivé par défaut ; l'activer demande l'autorisation des notifications.
- **BREAKING** (comportement) : l'exigence iOS « Résumé quotidien au premier plan » est remplacée.

## Capabilities

### New Capabilities

_Aucune._

### Modified Capabilities

- `daily-digest` : notification quand le résumé automatique est prêt, et son réglage.
- `ios-app` : le résumé quotidien et le rafraîchissement peuvent se faire en arrière-plan ; « Résumé quotidien au premier plan » est retirée.

## Impact

- `App/CairnApp.swift` (tâche d'arrière-plan de la scène iOS, délégué de notifications), `App/AppState.swift` (production du résumé hors premier plan, notification), `App/DigestViews.swift` (réglage), `DigestSettings`.
- `project.yml` : iOS `UIBackgroundModes` (`fetch`) et `BGTaskSchedulerPermittedIdentifiers`.
- Frameworks système : BackgroundTasks (iOS), UserNotifications (Mac et iOS). Aucune dépendance externe.
- Rien côté macOS quand l'app est quittée : aucun processus ne tourne (inchangé).
