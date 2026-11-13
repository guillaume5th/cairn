## ADDED Requirements

### Requirement: Rafraîchir automatiquement
Le système SHALL rafraîchir tous les flux abonnés à intervalle régulier tant que l'application tourne, fenêtre ouverte ou fermée. L'intervalle MUST se compter depuis la fin du dernier rafraîchissement, qu'il soit dû au lancement, à une demande ou au rafraîchissement automatique. Un rafraîchissement automatique MUST NOT être lancé pendant qu'un autre rafraîchissement est en cours.

#### Scenario: Intervalle écoulé
- **GIVEN** la fréquence est réglée sur 30 minutes
- **WHEN** 30 minutes se sont écoulées depuis la fin du dernier rafraîchissement
- **THEN** les flux sont récupérés et les nouveaux articles apparaissent

#### Scenario: Fenêtre fermée
- **GIVEN** l'application tourne sans fenêtre ouverte
- **WHEN** l'intervalle est écoulé
- **THEN** les flux sont récupérés

#### Scenario: Rafraîchissement à la demande entre-temps
- **GIVEN** la fréquence est réglée sur 30 minutes
- **WHEN** l'utilisateur appuie sur ⌘R 20 minutes après le dernier rafraîchissement
- **THEN** le prochain rafraîchissement automatique a lieu 30 minutes après la fin de celui-ci

#### Scenario: Rafraîchissement en cours
- **WHEN** l'intervalle s'écoule pendant un rafraîchissement
- **THEN** aucun second rafraîchissement n'est lancé

#### Scenario: Retour de veille
- **WHEN** le Mac sort de veille après plus d'un intervalle
- **THEN** un rafraîchissement a lieu dans la minute

### Requirement: Fréquence du rafraîchissement automatique
Le système SHALL proposer dans les Réglages le choix de la fréquence du rafraîchissement automatique : Jamais, toutes les 15 minutes, 30 minutes, 1 heure ou 2 heures. La valeur par défaut MUST être 30 minutes. « Jamais » MUST arrêter le rafraîchissement automatique sans changer le rafraîchissement au lancement ni à la demande.

#### Scenario: Valeur par défaut
- **WHEN** l'utilisateur ouvre les Réglages pour la première fois
- **THEN** la fréquence indique 30 minutes

#### Scenario: Jamais
- **GIVEN** la fréquence est réglée sur Jamais
- **WHEN** l'application reste ouverte plusieurs heures
- **THEN** aucun rafraîchissement automatique n'a lieu, et ⌘R rafraîchit toujours

#### Scenario: Intervalle raccourci
- **GIVEN** le dernier rafraîchissement date de 20 minutes
- **WHEN** l'utilisateur passe la fréquence de 30 à 15 minutes
- **THEN** un rafraîchissement a lieu dans la minute
