# Spec Delta

## MODIFIED Requirements

### Requirement: Choix du moteur d'IA
Le système SHALL proposer quatre moteurs : deux qui tournent sur la machine, le modèle d'Apple intégré au système (par défaut) et un serveur Ollama dont l'adresse (http://localhost:11434 par défaut) et le nom du modèle se règlent ; et deux qui passent par Anthropic, « Claude Code » (la CLI Claude Code installée sur ce Mac, avec le compte qui y est connecté) et « Claude (API) » (une clé API Anthropic). Avec un moteur local, le contenu des articles MUST NOT être envoyé à un autre service.

#### Scenario: Moteur Apple
- **GIVEN** le moteur choisi est celui d'Apple et il est disponible sur ce Mac
- **WHEN** le résumé est produit
- **THEN** il est rédigé par le modèle d'Apple, sans accès réseau

#### Scenario: Moteur Ollama
- **GIVEN** le moteur choisi est Ollama avec le modèle « llama3.2 »
- **WHEN** le résumé est produit
- **THEN** il est rédigé par ce modèle via le serveur Ollama réglé

#### Scenario: Moteur Claude Code
- **GIVEN** le moteur choisi est Claude Code, que la CLI est installée et connectée à un compte
- **WHEN** le résumé est produit
- **THEN** il est rédigé par Claude via ce compte, sans clé API, et le moteur affiché est « Claude Code »

#### Scenario: Moteur Claude API
- **GIVEN** le moteur choisi est Claude (API) et une clé API est enregistrée
- **WHEN** le résumé est produit
- **THEN** il est rédigé par le modèle Claude réglé via l'API Anthropic, et le moteur affiché porte le nom de ce modèle

### Requirement: Échec du résumé
Le système SHALL, quand le moteur est indisponible ou échoue, n'enregistrer aucun résumé et afficher un message qui dit pourquoi (par exemple : Apple Intelligence désactivé, serveur Ollama injoignable, modèle introuvable, CLI Claude Code introuvable ou non connectée, clé API absente ou refusée, quota atteint). L'échec compte comme la tentative du jour.

#### Scenario: Ollama arrêté
- **GIVEN** le moteur choisi est Ollama et le serveur ne répond pas
- **WHEN** l'heure du résumé arrive
- **THEN** un message indique que le serveur Ollama est injoignable, aucun résumé n'est enregistré, et aucune nouvelle tentative automatique n'a lieu ce jour-là

#### Scenario: Modèle d'Apple indisponible
- **GIVEN** le moteur choisi est celui d'Apple et Apple Intelligence n'est pas disponible sur ce Mac
- **WHEN** le résumé est produit
- **THEN** un message en donne la raison et aucun résumé n'est enregistré

#### Scenario: CLI Claude Code introuvable
- **GIVEN** le moteur choisi est Claude Code et la CLI n'est pas au chemin réglé
- **WHEN** le résumé est produit
- **THEN** un message indique que Claude Code est introuvable et où le régler, et aucun résumé n'est enregistré

#### Scenario: Claude Code non connecté
- **GIVEN** le moteur choisi est Claude Code et la CLI n'est connectée à aucun compte
- **WHEN** le résumé est produit
- **THEN** un message demande de lancer « claude » dans un terminal pour se connecter, et aucun résumé n'est enregistré

#### Scenario: Clé API absente ou refusée
- **GIVEN** le moteur choisi est Claude (API) et aucune clé n'est enregistrée, ou Anthropic la refuse
- **WHEN** le résumé est produit
- **THEN** un message indique que la clé manque ou est invalide, et aucun résumé n'est enregistré

## ADDED Requirements

### Requirement: Moteurs Claude : envoi à Anthropic et clé
Les Réglages MUST indiquer, quand un moteur Claude est choisi, que le contenu des articles résumés est envoyé à Anthropic. Le moteur Claude Code MUST NOT pouvoir lancer de commande, lire ou écrire de fichier, ni utiliser d'outil. La clé API MUST être gardée dans le trousseau macOS.

#### Scenario: Avertissement d'envoi
- **WHEN** l'utilisateur choisit un moteur Claude dans les Réglages
- **THEN** les Réglages indiquent que le contenu des articles résumés est envoyé à Anthropic

#### Scenario: Article qui tente de détourner Claude Code
- **GIVEN** le moteur choisi est Claude Code et un article contient des instructions demandant d'exécuter une commande
- **WHEN** le résumé est produit
- **THEN** aucune commande n'est exécutée et aucun fichier n'est lu ni modifié

#### Scenario: Clé API gardée hors des réglages
- **WHEN** l'utilisateur enregistre une clé API Anthropic
- **THEN** elle est gardée dans le trousseau macOS, et elle n'apparaît ni dans les réglages en clair ni dans les sauvegardes
