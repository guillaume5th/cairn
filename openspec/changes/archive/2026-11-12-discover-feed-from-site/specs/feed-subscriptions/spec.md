# Spec Delta

## MODIFIED Requirements

### Requirement: Ajouter un abonnement par URL
Le système SHALL permettre d'ajouter un abonnement à partir de l'URL d'un flux RSS ou Atom, ou de l'adresse d'un site qui en déclare un. La saisie MUST se faire, sur tous les appareils, dans une alerte avec un champ URL, comme « Nouveau dossier ». Le système MUST vérifier que l'URL retenue renvoie un flux lisible avant d'enregistrer l'abonnement, et utiliser le titre du flux comme nom de l'abonnement.

#### Scenario: Flux valide
- **WHEN** l'utilisateur saisit l'URL d'un flux RSS ou Atom valide
- **THEN** l'abonnement est enregistré avec le titre du flux et ses articles apparaissent

#### Scenario: URL invalide ou injoignable
- **WHEN** l'utilisateur saisit une URL injoignable, ou une page qui n'est pas un flux et où aucun flux n'est trouvé
- **THEN** aucun abonnement n'est créé et un message d'erreur explique le problème

#### Scenario: Flux déjà suivi
- **WHEN** l'utilisateur saisit l'URL d'un flux auquel il est déjà abonné, ou celle d'un site dont le seul flux est déjà suivi
- **THEN** aucun doublon n'est créé et l'utilisateur en est informé

## ADDED Requirements

### Requirement: Découvrir le flux d'un site
Le système SHALL, quand l'adresse saisie renvoie une page web plutôt qu'un flux, chercher les flux RSS, Atom ou JSON Feed qu'elle déclare, puis, si elle n'en déclare aucun, essayer les emplacements usuels du site (`/feed`, `/rss`, `/rss.xml`, `/feed.xml`, `/atom.xml`, `/index.xml`). Un seul flux trouvé MUST être ajouté directement.

#### Scenario: Site qui déclare son flux
- **GIVEN** la page d'accueil de `https://exemple.com` déclare un flux Atom
- **WHEN** l'utilisateur saisit `https://exemple.com`
- **THEN** l'abonnement à ce flux est créé, avec le titre du flux

#### Scenario: Flux à un emplacement usuel
- **GIVEN** la page d'un site ne déclare aucun flux mais `https://exemple.com/feed` en est un
- **WHEN** l'utilisateur saisit l'adresse du site
- **THEN** l'abonnement à `https://exemple.com/feed` est créé

#### Scenario: Aucun flux trouvé
- **WHEN** l'utilisateur saisit l'adresse d'un site qui n'a aucun flux
- **THEN** aucun abonnement n'est créé et un message indique qu'aucun flux n'a été trouvé sur ce site

### Requirement: Choisir parmi plusieurs flux
Le système SHALL, quand une page déclare plusieurs flux, les proposer à l'utilisateur avec le titre et l'adresse de chacun, et n'ajouter que celui qu'il choisit. Les flux déjà suivis MUST être signalés comme tels et ne pas pouvoir être ajoutés de nouveau.

#### Scenario: Articles et commentaires
- **GIVEN** un site déclare un flux des articles et un flux des commentaires
- **WHEN** l'utilisateur saisit l'adresse du site
- **THEN** les deux flux sont proposés et seul celui qu'il choisit devient un abonnement

#### Scenario: Annuler le choix
- **WHEN** l'utilisateur annule le choix entre plusieurs flux
- **THEN** aucun abonnement n'est créé

### Requirement: Adresse sans schéma
Le système SHALL accepter une adresse saisie sans schéma (« exemple.com » ou « exemple.com/blog ») en la complétant par `https://`.

#### Scenario: Nom de domaine seul
- **WHEN** l'utilisateur saisit « exemple.com »
- **THEN** Cairn cherche le flux à `https://exemple.com`
