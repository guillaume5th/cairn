# ios-app Specification

## Purpose
Définit ce qui diffère quand Cairn tourne sur iPhone et iPad : installation, données propres à l'appareil, mise en page, accès aux commandes sans barre des menus, réglages, cycle de vie et résumé quotidien. Les autres exigences valent sur iOS comme sur Mac, sauf les gestes propres au Mac (clic droit, ⌘-clic, Dock, ⌘Q) remplacés par les gestes standard d'iOS.

## Requirements

### Requirement: Application universelle iPhone et iPad
Le système SHALL fournir une application iOS qui s'installe et tourne sur iPhone et sur iPad, avec les mêmes fonctions que l'app Mac : abonnements et dossiers, lecture, recherche, cairns et tags, résumés d'articles et résumés quotidiens, import et export OPML.

#### Scenario: Installation sur iPhone
- **WHEN** l'utilisateur construit et installe l'app depuis Xcode sur son iPhone
- **THEN** Cairn se lance et permet d'ajouter un abonnement et de lire ses articles

#### Scenario: Installation sur iPad
- **WHEN** l'utilisateur construit et installe l'app depuis Xcode sur son iPad
- **THEN** Cairn se lance avec la même bibliothèque vide, prête à recevoir des abonnements

### Requirement: Données propres à l'appareil
Le système SHALL conserver la bibliothèque (abonnements, articles, cairns, tags, résumés) et les réglages sur l'appareil, sans synchronisation avec un autre appareil. L'import et l'export OPML MUST permettre de transférer ses abonnements entre appareils.

#### Scenario: Pas de synchronisation
- **GIVEN** l'utilisateur garde un article dans un cairn sur son Mac
- **WHEN** il ouvre Cairn sur son iPhone
- **THEN** l'article n'apparaît pas dans le cairn de l'iPhone

#### Scenario: Transfert des abonnements par OPML
- **GIVEN** l'utilisateur a exporté ses abonnements en OPML depuis son Mac vers un emplacement accessible à l'iPhone (iCloud Drive, AirDrop, Fichiers)
- **WHEN** il importe ce fichier dans Cairn sur l'iPhone
- **THEN** les abonnements sont créés sur l'iPhone, rangés dans leurs dossiers

### Requirement: Mise en page selon l'appareil
Le système SHALL afficher sur iPad la barre latérale, la liste et le volet de lecture côte à côte, et sur iPhone (ou dans une fenêtre étroite sur iPad) une navigation empilée : barre latérale, puis liste, puis article, avec un retour à l'écran précédent.

#### Scenario: iPad en paysage
- **WHEN** l'utilisateur ouvre Cairn sur un iPad en paysage
- **THEN** la liste d'articles et l'article sélectionné sont visibles en même temps

#### Scenario: iPhone
- **GIVEN** l'utilisateur affiche « Tous les articles » sur iPhone
- **WHEN** il touche un article
- **THEN** l'article s'affiche en plein écran, marqué comme lu, avec un bouton pour revenir à la liste

### Requirement: Retour à la liste après « non lu » sur iPhone
Le système SHALL, en largeur compacte (iPhone, ou iPad dans une fenêtre étroite), revenir à la liste d'où vient l'article quand l'utilisateur marque comme non lu l'article affiché. En largeur normale, l'article MUST rester affiché.

#### Scenario: Non lu sur iPhone
- **GIVEN** l'utilisateur lit un article d'un abonnement sur iPhone
- **WHEN** il touche « Marquer comme non lu »
- **THEN** la liste de cet abonnement s'affiche et l'article y apparaît comme non lu

#### Scenario: Non lu sur iPad
- **GIVEN** l'utilisateur lit un article sur iPad en paysage
- **WHEN** il touche « Marquer comme non lu »
- **THEN** l'article reste affiché et apparaît comme non lu dans la liste à côté

### Requirement: Commandes accessibles sans barre des menus
Le système SHALL rendre accessibles depuis l'interface, sans clavier, les commandes que le Mac place dans la barre des menus : ajouter un abonnement, importer et exporter OPML, rafraîchir, générer le résumé maintenant, ouvrir les Réglages.

#### Scenario: Import OPML sur iPhone
- **WHEN** l'utilisateur choisit « Importer OPML… » depuis la barre latérale
- **THEN** le sélecteur de fichiers du système s'ouvre et le fichier choisi est importé

#### Scenario: Rafraîchir en tirant la liste
- **WHEN** l'utilisateur tire la liste d'articles vers le bas
- **THEN** tous les abonnements sont rafraîchis, comme avec la commande Rafraîchir

### Requirement: Raccourcis clavier sur iPad
Le système SHALL accepter sur iPad avec clavier les mêmes raccourcis que sur Mac pour ajouter un abonnement (⌘N), rafraîchir (⌘R), rechercher (⌘F) et régler la taille du texte (⌘+, ⌘−, ⌘0).

#### Scenario: Rafraîchir au clavier
- **GIVEN** un clavier est connecté à l'iPad
- **WHEN** l'utilisateur appuie sur ⌘R
- **THEN** tous les abonnements sont rafraîchis

### Requirement: Réglages sur iOS
Le système SHALL présenter les Réglages dans une feuille qui regroupe les réglages du résumé (heure, moteur, adresse et modèle Ollama, conservation) et les préférences d'affichage, que le Mac propose aussi dans son menu Présentation : taille du texte du panneau de lecture et icônes dans la liste d'articles.

#### Scenario: Changer la taille du texte sur iPhone
- **WHEN** l'utilisateur agrandit le texte dans les Réglages puis ouvre un article
- **THEN** l'article s'affiche avec la taille choisie, conservée au lancement suivant

### Requirement: Cycle de vie sur iOS
Le système SHALL enregistrer les modifications en cours quand l'app passe en arrière-plan, pour qu'aucune modification ne soit perdue si le système la termine ensuite. Le travail de démarrage MUST n'être fait qu'une fois par lancement, pas à chaque retour au premier plan.

#### Scenario: App fermée par le système
- **GIVEN** l'utilisateur vient de garder un article dans un cairn
- **WHEN** il quitte l'app et iOS la termine en arrière-plan
- **THEN** l'article est toujours gardé au lancement suivant

#### Scenario: Retour au premier plan
- **GIVEN** l'app a démarré puis est passée en arrière-plan
- **WHEN** l'utilisateur revient dans l'app
- **THEN** aucune purge n'est relancée

### Requirement: Résumé quotidien au premier plan
Le système SHALL produire le résumé quotidien sur iOS uniquement quand l'app est au premier plan : au lancement ou au retour dans l'app si l'heure réglée est passée et qu'aucun résumé n'a été tenté ce jour-là, ou à l'heure réglée si l'app est ouverte à ce moment.

#### Scenario: Heure passée pendant que l'app était en arrière-plan
- **GIVEN** l'heure du résumé est 8 h et l'app est en arrière-plan depuis la veille
- **WHEN** l'utilisateur revient dans l'app à 9 h
- **THEN** le résumé du jour est produit

#### Scenario: Pas de résumé en arrière-plan
- **GIVEN** l'app est en arrière-plan
- **WHEN** l'heure du résumé arrive
- **THEN** aucun résumé n'est produit avant que l'utilisateur revienne dans l'app

### Requirement: Moteur Ollama sur le réseau local
Le système SHALL permettre d'utiliser un serveur Ollama du réseau local en HTTP (par exemple `http://192.168.1.10:11434`). À la première connexion, iOS MUST demander l'autorisation d'accéder au réseau local ; si elle est refusée, le système affiche le message « serveur Ollama injoignable » existant.

#### Scenario: Serveur Ollama sur le Mac
- **GIVEN** Ollama tourne sur un Mac du même réseau et écoute sur toutes les interfaces
- **WHEN** l'utilisateur règle l'adresse de ce Mac dans les Réglages de l'iPhone et accepte l'accès au réseau local
- **THEN** la liste des modèles installés s'affiche et le résumé d'article fonctionne

#### Scenario: Apple Intelligence indisponible sur l'appareil
- **GIVEN** le moteur choisi est celui d'Apple et l'iPhone ne prend pas en charge Apple Intelligence
- **WHEN** l'utilisateur demande un résumé
- **THEN** un message explique que cet appareil ne prend pas en charge Apple Intelligence et propose Ollama
