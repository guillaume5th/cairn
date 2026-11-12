# article-summary Specification

## Purpose

Résumer à la demande l'article consulté avec l'IA locale (Apple Intelligence ou Ollama), afficher ce résumé en haut de l'article et le conserver avec lui.

## Requirements

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

### Requirement: Échec du résumé d'un article
Le système SHALL, quand le moteur échoue (Apple Intelligence indisponible, serveur Ollama injoignable, modèle absent, délai dépassé), afficher dans l'encadré un message qui explique la cause, et MUST laisser l'utilisateur réessayer. Un échec MUST NOT effacer un résumé déjà conservé pour cet article.

#### Scenario: Ollama injoignable
- **GIVEN** le moteur choisi est Ollama et le serveur ne répond pas
- **WHEN** l'utilisateur choisit « Résumer »
- **THEN** l'encadré indique que le serveur Ollama est injoignable et propose de réessayer

#### Scenario: Échec d'une régénération
- **GIVEN** l'article a déjà un résumé
- **WHEN** l'utilisateur choisit « Régénérer » et que le moteur échoue
- **THEN** le message d'erreur s'affiche et le résumé précédent est conservé

### Requirement: Conserver le résumé avec l'article
Le système SHALL conserver le résumé d'un article (texte, date, moteur) avec l'article : revenir sur l'article ou relancer l'app MUST afficher le résumé sans solliciter le moteur. L'action « Régénérer » remplace le résumé conservé par un nouveau. Le résumé suit l'article : il reste avec un article gardé dans un cairn, et il est supprimé avec l'article quand celui-ci est purgé ou supprimé.

#### Scenario: Revenir sur un article résumé
- **GIVEN** l'article A a été résumé
- **WHEN** l'utilisateur affiche un autre article, quitte et relance l'app, puis revient sur A
- **THEN** le résumé de A s'affiche immédiatement, sans nouvel appel au moteur

#### Scenario: Régénérer
- **GIVEN** l'article affiché a un résumé
- **WHEN** l'utilisateur choisit « Régénérer » et que le moteur répond
- **THEN** le nouveau résumé, avec sa date et son moteur, remplace l'ancien

#### Scenario: Article gardé
- **GIVEN** un article résumé est gardé dans un cairn
- **WHEN** la purge supprime les articles non gardés de plus de 30 jours
- **THEN** l'article et son résumé sont conservés

### Requirement: Masquer et supprimer le résumé d'un article
Le système SHALL permettre de masquer le résumé d'un article (l'encadré se réduit à sa ligne d'en-tête) et de l'afficher de nouveau ; ce choix MUST valoir pour les articles suivants jusqu'à ce que l'utilisateur affiche de nouveau le résumé. Le système SHALL aussi permettre de supprimer le résumé d'un article, sans confirmation : l'encadré disparaît et l'action « Résumer » est de nouveau proposée.

#### Scenario: Masquer
- **GIVEN** l'article affiché a un résumé
- **WHEN** l'utilisateur masque le résumé puis affiche un autre article résumé
- **THEN** seuls l'en-tête de l'encadré et le contenu de l'article sont visibles

#### Scenario: Supprimer
- **WHEN** l'utilisateur supprime le résumé de l'article affiché
- **THEN** l'encadré disparaît, le résumé n'est plus conservé et la barre d'outils propose « Résumer »

### Requirement: Listes dans les résumés
Le système SHALL afficher les éléments de liste Markdown (« * », « - », « + ») des résumés, d'articles comme quotidiens, sous forme de puces, avec un retrait par niveau d'imbrication.

#### Scenario: Puces
- **WHEN** un résumé contient des lignes commençant par « * »
- **THEN** elles s'affichent comme une liste à puces, sans l'astérisque
