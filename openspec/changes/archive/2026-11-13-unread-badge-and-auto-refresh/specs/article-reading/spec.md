## ADDED Requirements

### Requirement: Badge des non-lus sur l'icône du Dock
Le système SHALL afficher sur l'icône du Dock le nombre d'articles non lus, le même que celui de « Tous les articles », fenêtre ouverte ou fermée. Aucun badge n'est affiché quand il n'y a aucun article non lu.

#### Scenario: Articles non lus
- **WHEN** la liste « Tous les articles » contient 7 articles non lus
- **THEN** l'icône de Cairn dans le Dock affiche 7

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur lit un article non lu
- **THEN** le badge diminue de 1

#### Scenario: Nouveaux articles fenêtre fermée
- **GIVEN** l'application tourne sans fenêtre ouverte
- **WHEN** un rafraîchissement apporte 3 nouveaux articles
- **THEN** le badge augmente de 3

#### Scenario: Tout est lu
- **WHEN** aucun article n'est non lu
- **THEN** l'icône du Dock n'affiche aucun badge

### Requirement: Réglage du badge
Le système SHALL proposer dans la section Affichage des Réglages un interrupteur « Badge sur l'icône », activé par défaut. Désactivé, l'icône du Dock MUST NOT afficher de badge. macOS n'affiche le badge qu'avec l'autorisation des pastilles : quand l'interrupteur est activé, le système MUST la demander, et MUST signaler dans les Réglages qu'elle a été refusée.

#### Scenario: Premier lancement
- **WHEN** l'utilisateur lance l'application pour la première fois
- **THEN** macOS demande l'autorisation des notifications de Cairn, pastilles comprises

#### Scenario: Pastilles refusées
- **GIVEN** les pastilles de Cairn sont désactivées dans Réglages Système
- **WHEN** l'utilisateur ouvre les Réglages avec « Badge sur l'icône » activé
- **THEN** un texte indique que les pastilles sont désactivées et comment les autoriser

#### Scenario: Désactiver le badge
- **WHEN** l'utilisateur désactive « Badge sur l'icône »
- **THEN** le badge disparaît aussitôt de l'icône du Dock

#### Scenario: Réactiver le badge
- **WHEN** l'utilisateur réactive « Badge sur l'icône » alors que 7 articles sont non lus
- **THEN** l'icône du Dock affiche 7 aussitôt
