# Design

## Context

Toutes les requêtes passent par `FeedFetcher.download` (flux, découverte, page complète, icônes). L'ajout d'un abonnement est une alerte de `ContentView` qui appelle `AppState.addFeed` ; les erreurs vont dans l'alerte de message. Voir proposal.md.

## Goals / Non-Goals

**Goals:** lire un flux protégé par HTTP Basic, sans stocker de secret ailleurs que dans le trousseau.

**Non-Goals:** OAuth, jetons, cookies de session ; identifiants différents pour deux flux du même site ; identifiants dans la sauvegarde ou dans l'adresse.

## Decisions

- **En-tête `Authorization: Basic` ajouté par `FeedFetcher` quand l'hôte a des identifiants.** `FeedFetcher` reçoit `credentials: (host) -> (user, password)?`, vide par défaut : `CairnCore` ne touche pas au trousseau et se teste avec une fonction. Alternative écartée : `URLCredentialStorage` et les défis d'authentification, qui exigent le *realm* exact du serveur.
- **Trousseau : mot de passe générique, service « Cairn — <hôte> ».** Un mot de passe Internet pour l'hôte risquerait de tomber sur l'élément d'une autre app et de faire demander l'accès au trousseau à chaque rafraîchissement.
- **Demande à l'ajout sur une erreur 401**, puis nouvel essai avec la même adresse ; « Identifiants… » sur un abonnement pour la suite, suivi d'un rafraîchissement.

## Risks / Trade-offs

- [L'app est signée ad hoc : après chaque mise à jour, macOS demande une fois par site d'autoriser l'accès à l'élément du trousseau] → c'est ce qui garde le mot de passe réservé à Cairn ; un élément ouvert à toutes les apps éviterait la demande mais exposerait le mot de passe.
- [Un site en http envoie les identifiants en clair] → c'est le choix du site ; le texte de l'alerte le dit.
- [Une redirection vers un autre hôte enverrait les identifiants à ce site] → un délégué de la requête retire l'en-tête quand l'hôte change.
