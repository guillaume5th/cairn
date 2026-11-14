# feed-fetching Specification

## Purpose

Récupère les nouveaux articles des flux abonnés, au lancement et à la demande, sans créer de doublons et sans qu'un flux défaillant bloque les autres.

## Requirements

### Requirement: Rafraîchir au lancement
Le système SHALL récupérer tous les flux abonnés au lancement de l'application, sans bloquer l'interface.

#### Scenario: Lancement de l'application
- **WHEN** l'utilisateur lance l'application
- **THEN** les flux sont récupérés et les nouveaux articles apparaissent pendant que l'interface reste utilisable

### Requirement: Rafraîchir à la demande
Le système SHALL permettre de rafraîchir tous les flux via une commande et le raccourci ⌘R. Une indication MUST signaler qu'un rafraîchissement est en cours, et une nouvelle demande pendant un rafraîchissement en cours MUST être ignorée.

#### Scenario: Rafraîchissement manuel
- **WHEN** l'utilisateur appuie sur ⌘R
- **THEN** tous les flux sont récupérés et un indicateur est visible jusqu'à la fin

#### Scenario: Double demande
- **WHEN** l'utilisateur appuie sur ⌘R alors qu'un rafraîchissement est en cours
- **THEN** aucun second rafraîchissement n'est lancé

### Requirement: Extraire les articles
Le système SHALL extraire de chaque flux RSS, Atom ou JSON Feed les articles avec leur titre, lien, date de publication et contenu (ou résumé). Un article sans date MUST recevoir la date de sa première récupération.

#### Scenario: Article sans date
- **WHEN** un flux contient un article sans date de publication
- **THEN** l'article est enregistré avec la date à laquelle il a été récupéré

### Requirement: Dédoublonner les articles
Le système MUST NOT créer deux fois le même article d'un même abonnement. Un article est identifié par son identifiant de flux (guid/id), ou à défaut par son lien. L'état lu, gardé, la note et les tags d'un article déjà connu MUST être préservés.

#### Scenario: Rafraîchissements successifs
- **WHEN** un flux est récupéré deux fois sans nouvel article
- **THEN** le nombre d'articles de cet abonnement est inchangé et leurs états sont conservés

### Requirement: Isoler les erreurs par flux
Le système SHALL continuer à récupérer les autres flux quand l'un d'eux échoue (réseau, format invalide), et MUST signaler l'erreur sur l'abonnement concerné.

#### Scenario: Un flux en erreur
- **WHEN** un flux est injoignable pendant un rafraîchissement
- **THEN** les autres flux sont mis à jour et l'abonnement en erreur affiche un indicateur d'erreur

### Requirement: Ignorer les articles déjà expirés
Le système MUST NOT réimporter un article dont la date de publication dépasse la durée de conservation réglée des articles non gardés.

#### Scenario: Ancien article toujours présent dans le flux
- **GIVEN** la durée de conservation est de 30 jours
- **WHEN** un flux contient un article publié il y a plus de 30 jours et absent de la base
- **THEN** cet article n'est pas ajouté

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
