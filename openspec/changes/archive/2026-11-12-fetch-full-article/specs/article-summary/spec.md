# Spec Delta

## MODIFIED Requirements

### Requirement: Résumer l'article consulté
Le système SHALL proposer, dans la barre d'outils de l'article affiché, une action « Résumer » qui le fait résumer en français par le moteur d'IA des réglages (Apple Intelligence ou Ollama), à partir de son titre et de son texte intégral quand il a été chargé, sinon du contenu fourni par le flux. Le résumé lui-même MUST NOT télécharger quoi que ce soit depuis le site de l'article. L'action MUST être indisponible sans contenu ou pendant un résumé en cours de cet article. Aucun résumé d'article n'est produit sans demande.

#### Scenario: Résumer un article
- **GIVEN** l'article affiché a un contenu et pas encore de résumé
- **WHEN** l'utilisateur choisit « Résumer »
- **THEN** le moteur choisi dans les réglages résume l'article et le résumé s'affiche en haut de l'article

#### Scenario: Résumer un article complet
- **GIVEN** le texte intégral de l'article a été chargé
- **WHEN** l'utilisateur choisit « Résumer »
- **THEN** le résumé porte sur le texte intégral, pas sur l'extrait du flux

#### Scenario: Article sans contenu
- **WHEN** l'article affiché n'a ni contenu fourni par le flux ni texte intégral
- **THEN** l'action « Résumer » est indisponible

#### Scenario: Aucun résumé automatique
- **WHEN** l'utilisateur affiche un article sans choisir « Résumer »
- **THEN** aucun moteur d'IA n'est sollicité pour cet article

### Requirement: Encadré du résumé
Le système SHALL afficher le résumé d'un article dans un encadré au-dessus de son contenu, avec la date du résumé et le nom du moteur utilisé. Pendant la génération, l'encadré MUST montrer une progression ; l'utilisateur peut continuer à lire et à changer d'article. Quand le résumé a été fait à partir d'un contenu court du flux (un simple extrait) et non du texte intégral, l'encadré MUST indiquer que le résumé porte sur l'extrait fourni par le flux. Le contenu de l'article reste affiché en dessous, inchangé.

#### Scenario: Pendant la génération
- **WHEN** l'utilisateur a choisi « Résumer » et que le moteur n'a pas encore répondu
- **THEN** l'encadré montre une progression et le contenu de l'article reste lisible en dessous

#### Scenario: Changer d'article pendant la génération
- **GIVEN** le résumé de l'article A est en cours
- **WHEN** l'utilisateur affiche l'article B puis revient sur A une fois le moteur ayant répondu
- **THEN** le résumé de A est affiché, et B n'a pas reçu le résumé de A

#### Scenario: Contenu court
- **WHEN** l'utilisateur résume un article dont le flux ne fournit qu'un court extrait et dont le texte intégral n'est pas chargé
- **THEN** l'encadré indique « Résumé de l'extrait fourni par le flux »

#### Scenario: Résumé du texte intégral
- **WHEN** l'utilisateur résume un article dont le texte intégral est chargé
- **THEN** l'encadré ne mentionne pas d'extrait
