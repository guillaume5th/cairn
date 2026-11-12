# Spec Delta

## ADDED Requirements

### Requirement: Notification du résumé prêt
Le système SHALL, quand le réglage « Me prévenir quand le résumé est prêt » est activé, envoyer une notification « Ton résumé du jour est prêt » dès qu'un résumé automatique est produit alors que Cairn n'est pas au premier plan. Toucher ou cliquer la notification MUST ouvrir Cairn sur ce résumé. Aucune notification n'est envoyée pour un résumé demandé à la main, ni en cas d'échec.

#### Scenario: Résumé produit fenêtre fermée sur Mac
- **GIVEN** le réglage est activé et la fenêtre de Cairn est fermée sans quitter l'app
- **WHEN** le résumé de 8 h est produit
- **THEN** une notification annonce que le résumé du jour est prêt

#### Scenario: Ouvrir le résumé depuis la notification
- **WHEN** l'utilisateur touche la notification
- **THEN** Cairn s'ouvre sur l'entrée « Résumés quotidiens » avec ce résumé affiché

#### Scenario: App au premier plan
- **GIVEN** le réglage est activé et Cairn est au premier plan
- **WHEN** le résumé du jour est produit
- **THEN** aucune notification n'est envoyée

#### Scenario: Réglage désactivé
- **GIVEN** le réglage est désactivé
- **WHEN** un résumé automatique est produit en arrière-plan
- **THEN** aucune notification n'est envoyée

### Requirement: Réglage des notifications du résumé
Le système SHALL proposer dans la section Résumé quotidien des Réglages un interrupteur « Me prévenir quand le résumé est prêt », désactivé par défaut. L'activer MUST demander l'autorisation des notifications au système ; si elle est refusée, l'interrupteur revient à désactivé et un message indique comment l'autoriser dans les réglages du système.

#### Scenario: Autorisation accordée
- **WHEN** l'utilisateur active l'interrupteur et accepte la demande du système
- **THEN** l'interrupteur reste activé

#### Scenario: Autorisation refusée
- **WHEN** l'utilisateur active l'interrupteur et refuse la demande du système
- **THEN** l'interrupteur revient à désactivé et un message explique comment autoriser les notifications
