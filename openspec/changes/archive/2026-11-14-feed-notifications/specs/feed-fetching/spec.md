## ADDED Requirements

### Requirement: Notifier les nouveaux articles d'un abonnement
Le système SHALL permettre d'activer, depuis le menu contextuel d'un ou plusieurs abonnements, « Notifier les nouveaux articles » (désactivé par défaut). Après un rafraîchissement, chaque abonnement ainsi réglé qui a reçu de nouveaux articles MUST poster une notification portant son nom et le titre de l'article, ou leur nombre s'il y en a plusieurs. Un clic sur la notification SHALL afficher cet abonnement. L'ajout d'un abonnement MUST NOT notifier.

#### Scenario: Un nouvel article
- **GIVEN** l'abonnement « Blog » est réglé pour notifier
- **WHEN** un rafraîchissement lui ajoute l'article « Sortie 2.0 »
- **THEN** une notification « Blog » annonce « Sortie 2.0 »

#### Scenario: Abonnement non réglé
- **WHEN** un rafraîchissement ajoute des articles à un abonnement non réglé pour notifier
- **THEN** aucune notification n'est postée

#### Scenario: Clic sur la notification
- **WHEN** l'utilisateur clique sur la notification de « Blog »
- **THEN** Cairn passe au premier plan et affiche l'abonnement « Blog »
