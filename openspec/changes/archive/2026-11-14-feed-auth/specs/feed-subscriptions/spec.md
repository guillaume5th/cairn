## ADDED Requirements

### Requirement: Flux protégé par mot de passe
Le système SHALL, quand le serveur d'une adresse ajoutée demande une authentification (HTTP 401), demander un identifiant et un mot de passe puis réessayer, et MUST proposer « Identifiants… » dans le menu d'un abonnement pour les changer ou les retirer. Les identifiants MUST être rangés dans le trousseau macOS, par site, envoyés en HTTP Basic à chaque requête vers ce site, et MUST NOT figurer dans la sauvegarde.

#### Scenario: Ajout d'un flux protégé
- **WHEN** l'utilisateur ajoute un flux dont le serveur répond 401
- **THEN** Cairn demande un identifiant et un mot de passe, puis s'abonne si le serveur les accepte

#### Scenario: Identifiants retirés
- **GIVEN** un abonnement avec des identifiants
- **WHEN** l'utilisateur vide l'identifiant dans « Identifiants… »
- **THEN** les identifiants sont retirés du trousseau et le rafraîchissement suivant échoue avec « Ce site demande un identifiant et un mot de passe. »
