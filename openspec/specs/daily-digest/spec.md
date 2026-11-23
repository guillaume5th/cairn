# daily-digest Specification

## Purpose

Résume chaque jour, à l'heure choisie et par une IA qui tourne sur la machine, les articles reçus dans les dernières 24 heures, et garde ces digests quelques jours.

## Requirements

### Requirement: Heure du digest quotidien
Le système SHALL, quand le digest automatique est activé, produire un digest par jour à l'heure réglée par l'utilisateur, 8 h par défaut. Le réglage MUST être conservé sur ce Mac entre les lancements. Le digest est produit tant que l'app tourne, même sans fenêtre ouverte ; aucun processus ne tourne quand elle est quittée.

#### Scenario: Heure atteinte app ouverte
- **GIVEN** l'heure du digest est 8 h et aucun digest n'a encore été tenté aujourd'hui
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** un digest est produit dans la minute

#### Scenario: Heure atteinte sans fenêtre
- **GIVEN** l'heure du digest est 8 h, aucun digest n'a encore été tenté aujourd'hui, et la fenêtre a été fermée sans quitter l'app
- **WHEN** il devient 8 h
- **THEN** un digest est produit dans la minute et apparaît à la réouverture de la fenêtre

#### Scenario: Changement de l'heure
- **GIVEN** le digest d'aujourd'hui n'a pas encore été tenté
- **WHEN** l'utilisateur règle l'heure sur un moment déjà passé aujourd'hui
- **THEN** le digest d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Une seule tentative automatique par jour
- **GIVEN** le digest d'aujourd'hui a déjà été tenté, avec succès ou non
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun autre digest automatique n'est lancé avant le lendemain

### Requirement: Rattrapage au lancement
Le système SHALL, quand le digest automatique est activé, produire au lancement le digest du jour quand l'heure réglée est passée et qu'aucun digest n'a été tenté depuis.

#### Scenario: App fermée à l'heure prévue
- **GIVEN** l'heure du digest est 8 h et l'app était fermée à 8 h
- **WHEN** l'utilisateur lance l'app à 10 h
- **THEN** un digest est produit après le rafraîchissement du lancement

#### Scenario: Lancement avant l'heure
- **WHEN** l'utilisateur lance l'app à 7 h avec l'heure réglée à 8 h
- **THEN** aucun digest n'est produit au lancement

#### Scenario: Plusieurs jours manqués
- **GIVEN** l'app est restée fermée trois jours
- **WHEN** l'utilisateur la lance après l'heure du digest
- **THEN** un seul digest est produit, celui du jour

#### Scenario: Digest automatique désactivé
- **GIVEN** le digest automatique est désactivé et l'app était fermée à l'heure du digest
- **WHEN** l'utilisateur lance l'app après cette heure
- **THEN** aucun digest n'est produit au lancement

### Requirement: Contenu du digest
Le système SHALL, pour produire un digest, rafraîchir d'abord les abonnements puis résumer les articles publiés dans les 24 heures précédant le moment du digest, tous abonnements confondus. Le digest MUST être rédigé dans la langue de l'interface (français ou anglais), regrouper les sujets proches, et être suivi de la liste des articles résumés avec leur titre, leur source et un lien vers chacun.

#### Scenario: Articles du jour
- **GIVEN** cinq articles ont été publiés dans les 24 dernières heures et d'autres avant
- **WHEN** le digest est produit
- **THEN** il porte sur ces cinq articles seulement, et les cinq figurent dans la liste qui le suit

#### Scenario: Lien vers un article
- **WHEN** l'utilisateur clique sur un article de la liste d'un digest
- **THEN** l'article s'ouvre dans le navigateur

#### Scenario: Aucun article
- **WHEN** aucun article n'a été publié dans les 24 dernières heures au moment du digest
- **THEN** aucun digest n'est créé et l'IA n'est pas appelée

#### Scenario: Digest dans la langue de l'interface
- **GIVEN** l'interface est en anglais
- **WHEN** le digest du jour est produit
- **THEN** le moteur reçoit la consigne de rédiger le digest en anglais

### Requirement: Choix du moteur d'IA
Le système SHALL proposer quatre moteurs : deux qui tournent sur la machine, le modèle d'Apple intégré au système (par défaut) et un serveur Ollama dont l'adresse (http://localhost:11434 par défaut) et le nom du modèle se règlent ; et deux qui passent par Anthropic, « Claude Code » (la CLI Claude Code installée sur ce Mac, avec le compte qui y est connecté) et « Claude (API) » (une clé API Anthropic). Avec un moteur local, le contenu des articles MUST NOT être envoyé à un autre service.

#### Scenario: Moteur Apple
- **GIVEN** le moteur choisi est celui d'Apple et il est disponible sur ce Mac
- **WHEN** le digest est produit
- **THEN** il est rédigé par le modèle d'Apple, sans accès réseau

#### Scenario: Moteur Ollama
- **GIVEN** le moteur choisi est Ollama avec le modèle « llama3.2 »
- **WHEN** le digest est produit
- **THEN** il est rédigé par ce modèle via le serveur Ollama réglé

#### Scenario: Moteur Claude Code
- **GIVEN** le moteur choisi est Claude Code, que la CLI est installée et connectée à un compte
- **WHEN** le digest est produit
- **THEN** il est rédigé par Claude via ce compte, sans clé API, et le moteur affiché est « Claude Code »

#### Scenario: Moteur Claude API
- **GIVEN** le moteur choisi est Claude (API) et une clé API est enregistrée
- **WHEN** le digest est produit
- **THEN** il est rédigé par le modèle Claude réglé via l'API Anthropic, et le moteur affiché porte le nom de ce modèle

### Requirement: Moteurs Claude : envoi à Anthropic et clé
Les Réglages MUST indiquer, quand un moteur Claude est choisi, que le contenu des articles résumés est envoyé à Anthropic. Le moteur Claude Code MUST NOT pouvoir lancer de commande, lire ou écrire de fichier, ni utiliser d'outil. La clé API MUST être gardée dans le trousseau macOS.

#### Scenario: Avertissement d'envoi
- **WHEN** l'utilisateur choisit un moteur Claude dans les Réglages
- **THEN** les Réglages indiquent que le contenu des articles résumés est envoyé à Anthropic

#### Scenario: Article qui tente de détourner Claude Code
- **GIVEN** le moteur choisi est Claude Code et un article contient des instructions demandant d'exécuter une commande
- **WHEN** le digest est produit
- **THEN** aucune commande n'est exécutée et aucun fichier n'est lu ni modifié

#### Scenario: Clé API gardée hors des réglages
- **WHEN** l'utilisateur enregistre une clé API Anthropic
- **THEN** elle est gardée dans le trousseau macOS, et elle n'apparaît ni dans les réglages en clair ni dans les sauvegardes

### Requirement: Échec du digest
Le système SHALL, quand le moteur est indisponible ou échoue, n'enregistrer aucun digest et afficher un message qui dit pourquoi (par exemple : Apple Intelligence désactivé, serveur Ollama injoignable, modèle introuvable, CLI Claude Code introuvable ou non connectée, clé API absente ou refusée, quota atteint). L'échec compte comme la tentative du jour.

#### Scenario: Ollama arrêté
- **GIVEN** le moteur choisi est Ollama et le serveur ne répond pas
- **WHEN** l'heure du digest arrive
- **THEN** un message indique que le serveur Ollama est injoignable, aucun digest n'est enregistré, et aucune nouvelle tentative automatique n'a lieu ce jour-là

#### Scenario: Modèle d'Apple indisponible
- **GIVEN** le moteur choisi est celui d'Apple et Apple Intelligence n'est pas disponible sur ce Mac
- **WHEN** le digest est produit
- **THEN** un message en donne la raison et aucun digest n'est enregistré

#### Scenario: CLI Claude Code introuvable
- **GIVEN** le moteur choisi est Claude Code et la CLI n'est pas au chemin réglé
- **WHEN** le digest est produit
- **THEN** un message indique que Claude Code est introuvable et où le régler, et aucun digest n'est enregistré

#### Scenario: Claude Code non connecté
- **GIVEN** le moteur choisi est Claude Code et la CLI n'est connectée à aucun compte
- **WHEN** le digest est produit
- **THEN** un message demande de lancer « claude » dans un terminal pour se connecter, et aucun digest n'est enregistré

#### Scenario: Clé API absente ou refusée
- **GIVEN** le moteur choisi est Claude (API) et aucune clé n'est enregistrée, ou Anthropic la refuse
- **WHEN** le digest est produit
- **THEN** un message indique que la clé manque ou est invalide, et aucun digest n'est enregistré

### Requirement: Générer le digest à la demande
Le système SHALL offrir une commande « Générer le digest maintenant », dans le menu Présentation et en bouton dans la barre d'outils de la liste des digests, qui produit un digest tout de suite, même si celui du jour a déjà été tenté. Menu et bouton MUST être inactifs pendant qu'un digest est en cours.

#### Scenario: Relance après échec
- **GIVEN** le digest de 8 h a échoué
- **WHEN** l'utilisateur choisit « Générer le digest maintenant » après avoir démarré Ollama
- **THEN** un digest est produit et ajouté à la liste

#### Scenario: Digest déjà en cours
- **WHEN** un digest est en cours
- **THEN** la commande du menu et le bouton de la barre d'outils sont grisés

#### Scenario: Bouton de la liste des digests
- **WHEN** l'utilisateur clique sur « Générer un digest » dans la barre d'outils de la liste des digests
- **THEN** un digest est produit et apparaît en tête de la liste

### Requirement: Rechercher dans les digests
Le système SHALL offrir dans la liste des digests un champ de recherche, au même endroit et avec le même raccourci (⌘F) que pour les articles, qui ne garde que les digests dont le texte, ou le titre ou la source d'un de leurs articles, contient le terme, sans tenir compte de la casse ni des accents. Changer d'entrée dans la barre latérale MUST vider la recherche.

#### Scenario: Recherche dans le texte
- **GIVEN** un seul digest parle de « tmux »
- **WHEN** l'utilisateur tape « TMUX » dans le champ de recherche de la liste des digests
- **THEN** seul ce digest est listé

#### Scenario: Recherche sur un article résumé
- **WHEN** l'utilisateur tape « emulateur » et qu'un digest liste l'article « AWS Émulateur »
- **THEN** ce digest est listé

#### Scenario: Aucun résultat
- **WHEN** aucun digest ne contient le terme
- **THEN** la liste est vide

### Requirement: Surligner le terme dans les digests
Pendant une recherche dans les digests, le système SHALL surligner le terme dans la liste et dans le digest affiché (texte, titres et sources des articles), selon la même règle que la recherche. Chaque ligne de la liste MUST afficher sous sa date un court extrait autour de la première occurrence du terme.

#### Scenario: Extrait dans la liste
- **WHEN** l'utilisateur recherche « tmux » et qu'un digest en parle
- **THEN** sa ligne affiche un court extrait autour de « tmux », mot surligné

#### Scenario: Surlignage dans le digest affiché
- **WHEN** l'utilisateur recherche « emulateur » et ouvre un digest qui liste l'article « AWS Émulateur »
- **THEN** « Émulateur » est surligné dans la liste des articles du digest

### Requirement: Afficher les digests
Le système SHALL afficher, quand l'utilisateur sélectionne l'entrée « Digests quotidiens » de la barre latérale, la liste des digests du plus récent au plus ancien, chacun désigné par sa date et son heure ; le digest sélectionné s'affiche dans le volet de lecture.

#### Scenario: Ouvrir un digest
- **WHEN** l'utilisateur sélectionne l'entrée « Digests quotidiens » puis un digest
- **THEN** son texte et la liste de ses articles s'affichent dans le volet de lecture

#### Scenario: Aucun digest
- **WHEN** l'utilisateur sélectionne l'entrée « Digests quotidiens » alors qu'il n'y a aucun digest
- **THEN** la liste est vide et le volet indique l'heure du prochain digest, ou que le digest automatique est désactivé

### Requirement: Supprimer un digest
Le système SHALL permettre de supprimer un digest depuis la liste des digests, par le bouton corbeille au-dessus du digest affiché, son menu contextuel, la touche Supprimer ou en balayant sa ligne vers la gauche, après confirmation. La suppression MUST être définitive et ne touche ni les articles ni la date de la dernière tentative.

#### Scenario: Supprimer le digest sélectionné
- **GIVEN** deux digests sont listés et le plus récent est sélectionné
- **WHEN** l'utilisateur choisit « Supprimer le digest… » puis confirme
- **THEN** ce digest disparaît et l'autre s'affiche dans le volet de lecture

#### Scenario: Balayer une ligne vers la gauche
- **WHEN** l'utilisateur balaie la ligne d'un digest vers la gauche, choisit la corbeille puis confirme
- **THEN** ce digest disparaît, même s'il n'était pas sélectionné

#### Scenario: Annuler la suppression
- **WHEN** l'utilisateur annule la confirmation
- **THEN** le digest reste

#### Scenario: Pas de nouveau digest automatique
- **GIVEN** le digest du jour a été produit puis supprimé
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun digest automatique n'est relancé avant le lendemain

### Requirement: Conservation des digests
Le système SHALL supprimer, au lancement et après chaque nouveau digest, les digests créés il y a plus de N jours. N vaut 7 par défaut et se règle entre 1 et 90 jours ; le réglage est conservé sur ce Mac.

#### Scenario: Durée par défaut
- **GIVEN** la durée de conservation n'a pas été changée
- **WHEN** un digest a été créé il y a 8 jours et l'app est lancée
- **THEN** ce digest est supprimé, et ceux des 7 derniers jours restent

#### Scenario: Durée allongée
- **GIVEN** la durée de conservation est réglée sur 30 jours
- **WHEN** un digest a été créé il y a 8 jours et l'app est lancée
- **THEN** ce digest reste

### Requirement: Réglages du digest
Le système SHALL offrir une fenêtre Réglages (⌘,) qui permet d'activer ou de désactiver le digest automatique et de régler l'heure du digest, le moteur, l'adresse et le modèle Ollama, et la durée de conservation. Les réglages Ollama MUST n'être affichés que lorsque le moteur Ollama est choisi.

#### Scenario: Choisir Ollama
- **WHEN** l'utilisateur choisit le moteur Ollama dans les Réglages
- **THEN** les champs adresse et modèle apparaissent, et le prochain digest utilise Ollama

### Requirement: Choisir un modèle Ollama installé
Le système SHALL proposer le modèle Ollama dans une liste des modèles installés sur le serveur réglé, relue à l'ouverture des Réglages, au changement d'adresse et à la demande. Quand le serveur est injoignable, la liste MUST garder le modèle actuel et afficher pourquoi ; un modèle réglé mais absent du serveur reste affiché comme « non installé ».

#### Scenario: Modèles installés
- **GIVEN** le serveur Ollama a les modèles « gemma4:latest » et « llama3.2:latest »
- **WHEN** l'utilisateur ouvre la liste des modèles
- **THEN** ces deux modèles sont proposés

#### Scenario: Serveur injoignable
- **GIVEN** l'adresse Ollama ne répond pas
- **WHEN** l'utilisateur ouvre les Réglages avec le moteur Ollama
- **THEN** la liste ne propose que le modèle actuel et un message indique que le serveur est injoignable

#### Scenario: Nouveau modèle installé
- **WHEN** l'utilisateur installe un modèle puis actualise la liste
- **THEN** le nouveau modèle est proposé

### Requirement: Saisie de la durée de conservation
Le système SHALL présenter la durée de conservation avec les contrôles standard du système : un libellé, puis un champ de saisie numérique accompagné de flèches pour augmenter ou diminuer la valeur, suivi de l'unité « jours ». L'heure du digest MUST utiliser le sélecteur d'heure standard. Une valeur saisie hors de 1 à 90 MUST être ramenée à la borne la plus proche.

#### Scenario: Saisie directe
- **WHEN** l'utilisateur tape 30 dans le champ de conservation
- **THEN** les digests sont gardés 30 jours

#### Scenario: Valeur hors bornes
- **WHEN** l'utilisateur tape 200
- **THEN** la valeur devient 90

### Requirement: Supprimer plusieurs digests
Le système SHALL permettre de sélectionner plusieurs digests (⌘-clic, ⇧-clic, ⌘A) et de les supprimer d'un coup, par le menu contextuel, la touche Supprimer ou la corbeille, après une seule confirmation qui indique leur nombre. Quand plusieurs digests sont sélectionnés, le volet de lecture MUST afficher « N digests sélectionnés » au lieu d'un digest.

#### Scenario: Supprimer trois digests
- **GIVEN** trois digests sont sélectionnés
- **WHEN** l'utilisateur appuie sur Supprimer puis confirme « Supprimer 3 digests ? »
- **THEN** les trois digests sont supprimés et le plus récent des digests restants s'affiche

#### Scenario: Volet de lecture
- **WHEN** l'utilisateur sélectionne deux digests
- **THEN** le volet de lecture affiche « 2 digests sélectionnés » et la corbeille supprime les deux

### Requirement: Notification du digest prêt
Le système SHALL, quand le réglage « Me prévenir quand le digest est prêt » est activé, envoyer une notification « Ton digest du jour est prêt » dès qu'un digest automatique est produit alors que Cairn n'est pas au premier plan. Toucher ou cliquer la notification MUST ouvrir Cairn sur ce digest. Aucune notification n'est envoyée pour un digest demandé à la main, ni en cas d'échec.

#### Scenario: Digest produit fenêtre fermée sur Mac
- **GIVEN** le réglage est activé et la fenêtre de Cairn est fermée sans quitter l'app
- **WHEN** le digest de 8 h est produit
- **THEN** une notification annonce que le digest du jour est prêt

#### Scenario: Ouvrir le digest depuis la notification
- **WHEN** l'utilisateur touche la notification
- **THEN** Cairn s'ouvre sur l'entrée « Digests quotidiens » avec ce digest affiché

#### Scenario: App au premier plan
- **GIVEN** le réglage est activé et Cairn est au premier plan
- **WHEN** le digest du jour est produit
- **THEN** aucune notification n'est envoyée

#### Scenario: Réglage désactivé
- **GIVEN** le réglage est désactivé
- **WHEN** un digest automatique est produit en arrière-plan
- **THEN** aucune notification n'est envoyée

### Requirement: Réglage des notifications du digest
Le système SHALL proposer dans la section Digest quotidien des Réglages un interrupteur « Me prévenir quand le digest est prêt », désactivé par défaut. L'activer MUST demander l'autorisation des notifications au système ; si elle est refusée, l'interrupteur revient à désactivé et un message indique comment l'autoriser dans les réglages du système.

#### Scenario: Autorisation accordée
- **WHEN** l'utilisateur active l'interrupteur et accepte la demande du système
- **THEN** l'interrupteur reste activé

#### Scenario: Autorisation refusée
- **WHEN** l'utilisateur active l'interrupteur et refuse la demande du système
- **THEN** l'interrupteur revient à désactivé et un message explique comment autoriser les notifications

### Requirement: Activer ou désactiver le digest automatique
Le système SHALL proposer dans la section Digest quotidien des Réglages un interrupteur « Digest automatique », activé par défaut et conservé sur ce Mac entre les lancements. Désactivé, le système MUST NOT produire de digest automatiquement ; la génération à la demande, l'entrée « Digests quotidiens » et les digests déjà produits restent disponibles.

#### Scenario: Désactiver
- **GIVEN** l'interrupteur « Digest automatique » est désactivé et l'heure du digest est 8 h
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** aucun digest n'est produit et aucune notification n'est envoyée

#### Scenario: Générer à la demande
- **GIVEN** l'interrupteur « Digest automatique » est désactivé
- **WHEN** l'utilisateur clique sur « Générer un digest »
- **THEN** un digest est produit comme d'habitude

#### Scenario: Réactiver après l'heure
- **GIVEN** l'interrupteur est désactivé, l'heure du digest est 8 h et aucun digest n'a été tenté aujourd'hui
- **WHEN** l'utilisateur l'active à 10 h
- **THEN** le digest d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Réglages grisés
- **WHEN** l'utilisateur désactive l'interrupteur
- **THEN** l'heure du digest et « Me prévenir quand le digest est prêt » sont grisés, et la durée de conservation reste modifiable

### Requirement: Un seul exemplaire par lien dans le digest
Le système SHALL ne résumer et ne lister qu'un article par lien normalisé, même quand ce lien est arrivé par plusieurs abonnements dans les 24 heures.

#### Scenario: Article reçu deux fois
- **GIVEN** le même lien est arrivé par deux abonnements dans les 24 dernières heures
- **WHEN** le digest est produit
- **THEN** l'article figure une seule fois dans le texte envoyé à l'IA et dans la liste qui suit le digest

### Requirement: Digests lus et non lus
Le système SHALL conserver pour chaque digest quotidien un état lu ou non lu. Un digest qui vient d'être produit MUST être non lu, et il devient lu dès qu'il est affiché seul dans le volet de lecture. La liste des digests MUST signaler chaque digest non lu par la même pastille que les articles non lus. Les digests produits avant l'existence de cet état sont lus.

#### Scenario: Nouveau digest
- **WHEN** un digest est produit, automatiquement ou à la demande
- **THEN** il apparaît dans la liste avec la pastille des non lus

#### Scenario: Afficher un digest
- **GIVEN** un digest non lu
- **WHEN** l'utilisateur l'affiche dans le volet de lecture, depuis la liste ou depuis sa notification
- **THEN** il est lu et sa pastille disparaît

#### Scenario: Plusieurs digests sélectionnés
- **GIVEN** deux digests non lus
- **WHEN** l'utilisateur les sélectionne ensemble
- **THEN** ils restent non lus, puisque le volet n'affiche que leur nombre

#### Scenario: Digests d'avant la mise à jour
- **GIVEN** des digests produits avant la version qui introduit l'état lu / non lu
- **WHEN** l'utilisateur ouvre la liste des digests après la mise à jour
- **THEN** aucun d'eux n'a la pastille des non lus

### Requirement: Changer l'état de lecture d'un digest
Le système SHALL offrir « Marquer comme lu » ou « Marquer comme non lu » dans le menu contextuel de la liste des digests, pour le digest cliqué ou toute la sélection, et en balayant une ligne vers la droite, avec les mêmes libellés et symboles que pour les articles. Un digest remis en non lu MUST le rester tant qu'il n'est pas affiché à nouveau.

#### Scenario: Remettre en non lu
- **GIVEN** le digest affiché est lu
- **WHEN** l'utilisateur choisit « Marquer comme non lu » dans le menu contextuel de sa ligne
- **THEN** la pastille des non lus réapparaît sur sa ligne

#### Scenario: Marquer plusieurs digests comme lus
- **GIVEN** trois digests sélectionnés dont au moins un non lu
- **WHEN** l'utilisateur choisit « Marquer comme lu » dans le menu contextuel
- **THEN** les trois sont lus

#### Scenario: Balayer une ligne
- **GIVEN** un digest non lu
- **WHEN** l'utilisateur balaie sa ligne vers la droite et choisit l'action proposée
- **THEN** le digest est lu

### Requirement: Filtre des digests non lus
Le système SHALL offrir dans la barre d'outils de la liste des digests le même bouton « Non lus seulement » que la liste des articles, qui ne garde que les digests non lus. Le digest affiché MUST rester listé tant qu'un autre n'est pas choisi, même devenu lu, et le filtre MUST NOT faire marquer lu un autre digest.

#### Scenario: Activer le filtre
- **GIVEN** deux digests non lus et trois lus
- **WHEN** l'utilisateur active « Non lus seulement »
- **THEN** la liste montre les deux non lus, plus le digest affiché s'il est lu

#### Scenario: Lire sous le filtre
- **GIVEN** le filtre est actif
- **WHEN** l'utilisateur affiche un digest non lu
- **THEN** il devient lu et reste dans la liste, et les autres non lus restent non lus

### Requirement: Tout marquer comme lu
Le système SHALL offrir dans la barre d'outils de la liste des digests le bouton « Tout marquer comme lu » de la liste des articles, qui marque lus tous les digests listés.

#### Scenario: Tout marquer
- **GIVEN** trois digests non lus
- **WHEN** l'utilisateur clique sur « Tout marquer comme lu »
- **THEN** les trois sont lus et l'entrée « Digests quotidiens » n'affiche plus de nombre

### Requirement: Mode sélection des digests
Le système SHALL offrir dans la barre d'outils de la liste des digests le bouton « Sélectionner » de la liste des articles : un clic coche ou décoche un digest, le titre de la liste donne le nombre de cochés, le volet de lecture affiche ce nombre, et Échap ou le même bouton quittent le mode sans rien changer.

#### Scenario: Cocher des digests
- **GIVEN** le mode sélection est actif
- **WHEN** l'utilisateur clique sur deux digests
- **THEN** ils sont cochés, le titre indique « 2 sélectionnés » et le volet de lecture « 2 digests sélectionnés »

#### Scenario: Quitter le mode
- **WHEN** l'utilisateur appuie sur Échap en mode sélection
- **THEN** les coches disparaissent et aucun digest n'est modifié

### Requirement: Actions du volet de lecture des digests
Le système SHALL offrir dans la barre d'outils du volet de lecture des digests, à côté de la corbeille, le bouton « Marquer comme lu / non lu » du lecteur d'articles. Il agit sur le digest affiché ou sur tous les digests sélectionnés, et il est grisé quand il n'y en a aucun.

#### Scenario: Remettre en non lu le digest affiché
- **GIVEN** le digest affiché est lu
- **WHEN** l'utilisateur clique sur « Marquer comme non lu » dans la barre d'outils du volet
- **THEN** sa ligne reprend la pastille des non lus et il reste affiché

#### Scenario: Plusieurs digests
- **GIVEN** trois digests sélectionnés dont un non lu
- **WHEN** l'utilisateur clique sur « Marquer comme lu » dans la barre d'outils du volet
- **THEN** les trois sont lus

### Requirement: Nombre de digests non lus
Le système SHALL afficher dans la barre latérale, sur l'entrée « Digests quotidiens », le nombre de digests non lus, et aucun nombre quand tous sont lus.

#### Scenario: Un nouveau digest
- **GIVEN** tous les digests sont lus
- **WHEN** un digest est produit
- **THEN** l'entrée « Digests quotidiens » affiche 1

#### Scenario: Tous lus
- **WHEN** l'utilisateur affiche le dernier digest non lu
- **THEN** l'entrée « Digests quotidiens » n'affiche plus de nombre
