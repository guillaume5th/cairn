# Spec Delta

## Purpose

Permet de lire dans Cairn le texte complet d'un article dont le flux ne fournit qu'un extrait, en récupérant le contenu principal de sa page web, à la demande ou automatiquement pour un abonnement.

## ADDED Requirements

### Requirement: Charger l'article complet
Le système SHALL proposer, dans le panneau de lecture d'un article qui a un lien web, une action « Charger l'article complet ». Elle télécharge la page de l'article, en extrait le contenu principal (sans navigation, publicités ni commentaires) et l'affiche à la place du contenu du flux, avec le même rendu. Pendant le chargement, le panneau MUST montrer une progression et rester lisible.

#### Scenario: Flux qui ne donne qu'un extrait
- **GIVEN** le flux d'un article ne fournit que les premières lignes
- **WHEN** l'utilisateur choisit « Charger l'article complet »
- **THEN** le texte complet de l'article s'affiche dans le panneau, sans les menus ni les publicités du site

#### Scenario: Article sans lien web
- **WHEN** l'article affiché n'a pas de lien http ou https
- **THEN** l'action « Charger l'article complet » est indisponible

### Requirement: Échec du chargement complet
Le système SHALL, quand la page ne peut pas être téléchargée ou qu'aucun contenu principal n'y est trouvé, garder le contenu du flux affiché et indiquer l'échec dans le panneau, avec la possibilité de réessayer ou d'ouvrir l'article dans le navigateur.

#### Scenario: Site injoignable
- **GIVEN** l'appareil est hors ligne
- **WHEN** l'utilisateur choisit « Charger l'article complet »
- **THEN** le contenu du flux reste affiché et un message indique que l'article complet n'a pas pu être chargé

#### Scenario: Page sans contenu principal
- **WHEN** la page de l'article ne contient pas de texte identifiable comme article
- **THEN** le contenu du flux reste affiché et un message l'indique

### Requirement: Conserver le texte intégral
Le système SHALL conserver le texte intégral chargé avec l'article, l'afficher à chaque nouvelle consultation sans le télécharger de nouveau, et le supprimer avec l'article. L'utilisateur MUST pouvoir revenir au contenu fourni par le flux, puis réafficher le texte intégral.

#### Scenario: Nouvelle consultation
- **GIVEN** le texte intégral d'un article a été chargé
- **WHEN** l'utilisateur affiche un autre article puis revient sur celui-ci, hors ligne
- **THEN** le texte intégral s'affiche

#### Scenario: Revenir au contenu du flux
- **GIVEN** le texte intégral d'un article est affiché
- **WHEN** l'utilisateur choisit « Afficher le contenu du flux »
- **THEN** le contenu fourni par le flux s'affiche, et « Afficher l'article complet » le réaffiche sans téléchargement

### Requirement: Article complet automatique par abonnement
Le système SHALL proposer dans le menu contextuel d'un abonnement une option « Toujours charger l'article complet », désactivée par défaut. Quand elle est activée, le texte intégral des nouveaux articles de cet abonnement MUST être récupéré après chaque rafraîchissement, sans bloquer le rafraîchissement des autres abonnements ; un échec laisse le contenu du flux.

#### Scenario: Nouvel article d'un abonnement en mode complet
- **GIVEN** l'option est activée pour un abonnement
- **WHEN** un rafraîchissement apporte un nouvel article de cet abonnement
- **THEN** son texte intégral est affiché dès sa première consultation, sans action de l'utilisateur

#### Scenario: Articles déjà présents
- **WHEN** l'utilisateur active l'option sur un abonnement
- **THEN** seuls les articles arrivés après l'activation sont chargés automatiquement

### Requirement: Sécurité du texte intégral
Le système MUST afficher le texte intégral avec les mêmes protections que le contenu du flux : aucun script de la page n'est exécuté, seuls les images distantes sont chargées, et les liens s'ouvrent dans le navigateur. Le téléchargement MUST NOT envoyer de cookies ni d'identifiants du navigateur.

#### Scenario: Page avec scripts
- **GIVEN** la page d'un article contient des scripts et des iframes
- **WHEN** son texte intégral est affiché
- **THEN** aucun script ne s'exécute et les iframes ne sont pas chargées
