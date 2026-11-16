# daily-digest Specification

## Purpose

Résume chaque jour, à l'heure choisie et par une IA qui tourne sur la machine, les articles reçus dans les dernières 24 heures, et garde ces résumés quelques jours.

## Requirements

### Requirement: Heure du résumé quotidien
Le système SHALL, quand le résumé automatique est activé, produire un résumé par jour à l'heure réglée par l'utilisateur, 8 h par défaut. Le réglage MUST être conservé sur ce Mac entre les lancements. Le résumé est produit tant que l'app tourne, même sans fenêtre ouverte ; aucun processus ne tourne quand elle est quittée.

#### Scenario: Heure atteinte app ouverte
- **GIVEN** l'heure du résumé est 8 h et aucun résumé n'a encore été tenté aujourd'hui
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** un résumé est produit dans la minute

#### Scenario: Heure atteinte sans fenêtre
- **GIVEN** l'heure du résumé est 8 h, aucun résumé n'a encore été tenté aujourd'hui, et la fenêtre a été fermée sans quitter l'app
- **WHEN** il devient 8 h
- **THEN** un résumé est produit dans la minute et apparaît à la réouverture de la fenêtre

#### Scenario: Changement de l'heure
- **GIVEN** le résumé d'aujourd'hui n'a pas encore été tenté
- **WHEN** l'utilisateur règle l'heure sur un moment déjà passé aujourd'hui
- **THEN** le résumé d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Une seule tentative automatique par jour
- **GIVEN** le résumé d'aujourd'hui a déjà été tenté, avec succès ou non
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun autre résumé automatique n'est lancé avant le lendemain

### Requirement: Rattrapage au lancement
Le système SHALL, quand le résumé automatique est activé, produire au lancement le résumé du jour quand l'heure réglée est passée et qu'aucun résumé n'a été tenté depuis.

#### Scenario: App fermée à l'heure prévue
- **GIVEN** l'heure du résumé est 8 h et l'app était fermée à 8 h
- **WHEN** l'utilisateur lance l'app à 10 h
- **THEN** un résumé est produit après le rafraîchissement du lancement

#### Scenario: Lancement avant l'heure
- **WHEN** l'utilisateur lance l'app à 7 h avec l'heure réglée à 8 h
- **THEN** aucun résumé n'est produit au lancement

#### Scenario: Plusieurs jours manqués
- **GIVEN** l'app est restée fermée trois jours
- **WHEN** l'utilisateur la lance après l'heure du résumé
- **THEN** un seul résumé est produit, celui du jour

#### Scenario: Résumé automatique désactivé
- **GIVEN** le résumé automatique est désactivé et l'app était fermée à l'heure du résumé
- **WHEN** l'utilisateur lance l'app après cette heure
- **THEN** aucun résumé n'est produit au lancement

### Requirement: Contenu du résumé
Le système SHALL, pour produire un résumé, rafraîchir d'abord les abonnements puis résumer les articles publiés dans les 24 heures précédant le moment du résumé, tous abonnements confondus. Le résumé MUST être rédigé en français, regrouper les sujets proches, et être suivi de la liste des articles résumés avec leur titre, leur source et un lien vers chacun.

#### Scenario: Articles du jour
- **GIVEN** cinq articles ont été publiés dans les 24 dernières heures et d'autres avant
- **WHEN** le résumé est produit
- **THEN** il porte sur ces cinq articles seulement, et les cinq figurent dans la liste qui le suit

#### Scenario: Lien vers un article
- **WHEN** l'utilisateur clique sur un article de la liste d'un résumé
- **THEN** l'article s'ouvre dans le navigateur

#### Scenario: Aucun article
- **WHEN** aucun article n'a été publié dans les 24 dernières heures au moment du résumé
- **THEN** aucun résumé n'est créé et l'IA n'est pas appelée

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

### Requirement: Générer le résumé à la demande
Le système SHALL offrir une commande « Générer le résumé maintenant », dans le menu Présentation et en bouton dans la barre d'outils de la liste des résumés, qui produit un résumé tout de suite, même si celui du jour a déjà été tenté. Menu et bouton MUST être inactifs pendant qu'un résumé est en cours.

#### Scenario: Relance après échec
- **GIVEN** le résumé de 8 h a échoué
- **WHEN** l'utilisateur choisit « Générer le résumé maintenant » après avoir démarré Ollama
- **THEN** un résumé est produit et ajouté à la liste

#### Scenario: Résumé déjà en cours
- **WHEN** un résumé est en cours
- **THEN** la commande du menu et le bouton de la barre d'outils sont grisés

#### Scenario: Bouton de la liste des résumés
- **WHEN** l'utilisateur clique sur « Générer un résumé » dans la barre d'outils de la liste des résumés
- **THEN** un résumé est produit et apparaît en tête de la liste

### Requirement: Rechercher dans les résumés
Le système SHALL offrir dans la liste des résumés un champ de recherche, au même endroit et avec le même raccourci (⌘F) que pour les articles, qui ne garde que les résumés dont le texte, ou le titre ou la source d'un de leurs articles, contient le terme, sans tenir compte de la casse ni des accents. Changer d'entrée dans la barre latérale MUST vider la recherche.

#### Scenario: Recherche dans le texte
- **GIVEN** un seul résumé parle de « tmux »
- **WHEN** l'utilisateur tape « TMUX » dans le champ de recherche de la liste des résumés
- **THEN** seul ce résumé est listé

#### Scenario: Recherche sur un article résumé
- **WHEN** l'utilisateur tape « emulateur » et qu'un résumé liste l'article « AWS Émulateur »
- **THEN** ce résumé est listé

#### Scenario: Aucun résultat
- **WHEN** aucun résumé ne contient le terme
- **THEN** la liste est vide

### Requirement: Surligner le terme dans les résumés
Pendant une recherche dans les résumés, le système SHALL surligner le terme dans la liste et dans le résumé affiché (texte, titres et sources des articles), selon la même règle que la recherche. Chaque ligne de la liste MUST afficher sous sa date un court extrait autour de la première occurrence du terme.

#### Scenario: Extrait dans la liste
- **WHEN** l'utilisateur recherche « tmux » et qu'un résumé en parle
- **THEN** sa ligne affiche un court extrait autour de « tmux », mot surligné

#### Scenario: Surlignage dans le résumé affiché
- **WHEN** l'utilisateur recherche « emulateur » et ouvre un résumé qui liste l'article « AWS Émulateur »
- **THEN** « Émulateur » est surligné dans la liste des articles du résumé

### Requirement: Afficher les résumés
Le système SHALL afficher, quand l'utilisateur sélectionne l'entrée « Résumés quotidiens » de la barre latérale, la liste des résumés du plus récent au plus ancien, chacun désigné par sa date et son heure ; le résumé sélectionné s'affiche dans le volet de lecture.

#### Scenario: Ouvrir un résumé
- **WHEN** l'utilisateur sélectionne l'entrée « Résumés quotidiens » puis un résumé
- **THEN** son texte et la liste de ses articles s'affichent dans le volet de lecture

#### Scenario: Aucun résumé
- **WHEN** l'utilisateur sélectionne l'entrée « Résumés quotidiens » alors qu'il n'y a aucun résumé
- **THEN** la liste est vide et le volet indique l'heure du prochain résumé, ou que le résumé automatique est désactivé

### Requirement: Supprimer un résumé
Le système SHALL permettre de supprimer un résumé depuis la liste des résumés, par le bouton corbeille au-dessus du résumé affiché, son menu contextuel, la touche Supprimer ou en balayant sa ligne vers la gauche, après confirmation. La suppression MUST être définitive et ne touche ni les articles ni la date de la dernière tentative.

#### Scenario: Supprimer le résumé sélectionné
- **GIVEN** deux résumés sont listés et le plus récent est sélectionné
- **WHEN** l'utilisateur choisit « Supprimer le résumé… » puis confirme
- **THEN** ce résumé disparaît et l'autre s'affiche dans le volet de lecture

#### Scenario: Balayer une ligne vers la gauche
- **WHEN** l'utilisateur balaie la ligne d'un résumé vers la gauche, choisit la corbeille puis confirme
- **THEN** ce résumé disparaît, même s'il n'était pas sélectionné

#### Scenario: Annuler la suppression
- **WHEN** l'utilisateur annule la confirmation
- **THEN** le résumé reste

#### Scenario: Pas de nouveau résumé automatique
- **GIVEN** le résumé du jour a été produit puis supprimé
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun résumé automatique n'est relancé avant le lendemain

### Requirement: Conservation des résumés
Le système SHALL supprimer, au lancement et après chaque nouveau résumé, les résumés créés il y a plus de N jours. N vaut 7 par défaut et se règle entre 1 et 90 jours ; le réglage est conservé sur ce Mac.

#### Scenario: Durée par défaut
- **GIVEN** la durée de conservation n'a pas été changée
- **WHEN** un résumé a été créé il y a 8 jours et l'app est lancée
- **THEN** ce résumé est supprimé, et ceux des 7 derniers jours restent

#### Scenario: Durée allongée
- **GIVEN** la durée de conservation est réglée sur 30 jours
- **WHEN** un résumé a été créé il y a 8 jours et l'app est lancée
- **THEN** ce résumé reste

### Requirement: Réglages du résumé
Le système SHALL offrir une fenêtre Réglages (⌘,) qui permet d'activer ou de désactiver le résumé automatique et de régler l'heure du résumé, le moteur, l'adresse et le modèle Ollama, et la durée de conservation. Les réglages Ollama MUST n'être affichés que lorsque le moteur Ollama est choisi.

#### Scenario: Choisir Ollama
- **WHEN** l'utilisateur choisit le moteur Ollama dans les Réglages
- **THEN** les champs adresse et modèle apparaissent, et le prochain résumé utilise Ollama

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
Le système SHALL présenter la durée de conservation avec les contrôles standard du système : un libellé, puis un champ de saisie numérique accompagné de flèches pour augmenter ou diminuer la valeur, suivi de l'unité « jours ». L'heure du résumé MUST utiliser le sélecteur d'heure standard. Une valeur saisie hors de 1 à 90 MUST être ramenée à la borne la plus proche.

#### Scenario: Saisie directe
- **WHEN** l'utilisateur tape 30 dans le champ de conservation
- **THEN** les résumés sont gardés 30 jours

#### Scenario: Valeur hors bornes
- **WHEN** l'utilisateur tape 200
- **THEN** la valeur devient 90

### Requirement: Supprimer plusieurs résumés
Le système SHALL permettre de sélectionner plusieurs résumés (⌘-clic, ⇧-clic, ⌘A) et de les supprimer d'un coup, par le menu contextuel, la touche Supprimer ou la corbeille, après une seule confirmation qui indique leur nombre. Quand plusieurs résumés sont sélectionnés, le volet de lecture MUST afficher « N résumés sélectionnés » au lieu d'un résumé.

#### Scenario: Supprimer trois résumés
- **GIVEN** trois résumés sont sélectionnés
- **WHEN** l'utilisateur appuie sur Supprimer puis confirme « Supprimer 3 résumés ? »
- **THEN** les trois résumés sont supprimés et le plus récent des résumés restants s'affiche

#### Scenario: Volet de lecture
- **WHEN** l'utilisateur sélectionne deux résumés
- **THEN** le volet de lecture affiche « 2 résumés sélectionnés » et la corbeille supprime les deux

### Requirement: Notification du résumé prêt
Le système SHALL, quand le réglage « Me prévenir quand le résumé est prêt » est activé, envoyer une notification « Ton résumé du jour est prêt » dès qu'un résumé automatique est produit alors que Cairn n'est pas au premier plan. Toucher ou cliquer la notification MUST ouvrir Cairn sur ce résumé. Aucune notification n'est envoyée pour un résumé demandé à la main, ni en cas d'échec.

#### Scenario: Résumé produit fenêtre fermée sur Mac
- **GIVEN** le réglage est activé et la fenêtre de Cairn est fermée sans quitter l'app
- **WHEN** le résumé de 8 h est produit
- **THEN** une notification annonce que le résumé du jour est prêt

#### Scenario: Ouvrir le résumé depuis la notification
- **WHEN** l'utilisateur touche la notification
- **THEN** Cairn s'ouvre sur l'entrée « Résumés quotidiens » avec ce résumé affiché

#### Scenario: App au premier plan
- **GIVEN** le réglage est activé et Cairn est au premier plan
- **WHEN** le résumé du jour est produit
- **THEN** aucune notification n'est envoyée

#### Scenario: Réglage désactivé
- **GIVEN** le réglage est désactivé
- **WHEN** un résumé automatique est produit en arrière-plan
- **THEN** aucune notification n'est envoyée

### Requirement: Réglage des notifications du résumé
Le système SHALL proposer dans la section Résumé quotidien des Réglages un interrupteur « Me prévenir quand le résumé est prêt », désactivé par défaut. L'activer MUST demander l'autorisation des notifications au système ; si elle est refusée, l'interrupteur revient à désactivé et un message indique comment l'autoriser dans les réglages du système.

#### Scenario: Autorisation accordée
- **WHEN** l'utilisateur active l'interrupteur et accepte la demande du système
- **THEN** l'interrupteur reste activé

#### Scenario: Autorisation refusée
- **WHEN** l'utilisateur active l'interrupteur et refuse la demande du système
- **THEN** l'interrupteur revient à désactivé et un message explique comment autoriser les notifications

### Requirement: Activer ou désactiver le résumé automatique
Le système SHALL proposer dans la section Résumé quotidien des Réglages un interrupteur « Résumé automatique », activé par défaut et conservé sur ce Mac entre les lancements. Désactivé, le système MUST NOT produire de résumé automatiquement ; la génération à la demande, l'entrée « Résumés quotidiens » et les résumés déjà produits restent disponibles.

#### Scenario: Désactiver
- **GIVEN** l'interrupteur « Résumé automatique » est désactivé et l'heure du résumé est 8 h
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** aucun résumé n'est produit et aucune notification n'est envoyée

#### Scenario: Générer à la demande
- **GIVEN** l'interrupteur « Résumé automatique » est désactivé
- **WHEN** l'utilisateur clique sur « Générer un résumé »
- **THEN** un résumé est produit comme d'habitude

#### Scenario: Réactiver après l'heure
- **GIVEN** l'interrupteur est désactivé, l'heure du résumé est 8 h et aucun résumé n'a été tenté aujourd'hui
- **WHEN** l'utilisateur l'active à 10 h
- **THEN** le résumé d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Réglages grisés
- **WHEN** l'utilisateur désactive l'interrupteur
- **THEN** l'heure du résumé et « Me prévenir quand le résumé est prêt » sont grisés, et la durée de conservation reste modifiable

### Requirement: Un seul exemplaire par lien dans le résumé
Le système SHALL ne résumer et ne lister qu'un article par lien normalisé, même quand ce lien est arrivé par plusieurs abonnements dans les 24 heures.

#### Scenario: Article reçu deux fois
- **GIVEN** le même lien est arrivé par deux abonnements dans les 24 dernières heures
- **WHEN** le résumé est produit
- **THEN** l'article figure une seule fois dans le texte envoyé à l'IA et dans la liste qui suit le résumé

### Requirement: Résumés lus et non lus
Le système SHALL conserver pour chaque résumé quotidien un état lu ou non lu. Un résumé qui vient d'être produit MUST être non lu, et il devient lu dès qu'il est affiché seul dans le volet de lecture. La liste des résumés MUST signaler chaque résumé non lu par la même pastille que les articles non lus. Les résumés produits avant l'existence de cet état sont lus.

#### Scenario: Nouveau résumé
- **WHEN** un résumé est produit, automatiquement ou à la demande
- **THEN** il apparaît dans la liste avec la pastille des non lus

#### Scenario: Afficher un résumé
- **GIVEN** un résumé non lu
- **WHEN** l'utilisateur l'affiche dans le volet de lecture, depuis la liste ou depuis sa notification
- **THEN** il est lu et sa pastille disparaît

#### Scenario: Plusieurs résumés sélectionnés
- **GIVEN** deux résumés non lus
- **WHEN** l'utilisateur les sélectionne ensemble
- **THEN** ils restent non lus, puisque le volet n'affiche que leur nombre

#### Scenario: Résumés d'avant la mise à jour
- **GIVEN** des résumés produits avant la version qui introduit l'état lu / non lu
- **WHEN** l'utilisateur ouvre la liste des résumés après la mise à jour
- **THEN** aucun d'eux n'a la pastille des non lus

### Requirement: Changer l'état de lecture d'un résumé
Le système SHALL offrir « Marquer comme lu » ou « Marquer comme non lu » dans le menu contextuel de la liste des résumés, pour le résumé cliqué ou toute la sélection, et en balayant une ligne vers la droite, avec les mêmes libellés et symboles que pour les articles. Un résumé remis en non lu MUST le rester tant qu'il n'est pas affiché à nouveau.

#### Scenario: Remettre en non lu
- **GIVEN** le résumé affiché est lu
- **WHEN** l'utilisateur choisit « Marquer comme non lu » dans le menu contextuel de sa ligne
- **THEN** la pastille des non lus réapparaît sur sa ligne

#### Scenario: Marquer plusieurs résumés comme lus
- **GIVEN** trois résumés sélectionnés dont au moins un non lu
- **WHEN** l'utilisateur choisit « Marquer comme lu » dans le menu contextuel
- **THEN** les trois sont lus

#### Scenario: Balayer une ligne
- **GIVEN** un résumé non lu
- **WHEN** l'utilisateur balaie sa ligne vers la droite et choisit l'action proposée
- **THEN** le résumé est lu

### Requirement: Filtre des résumés non lus
Le système SHALL offrir dans la barre d'outils de la liste des résumés le même bouton « Non lus seulement » que la liste des articles, qui ne garde que les résumés non lus. Le résumé affiché MUST rester listé tant qu'un autre n'est pas choisi, même devenu lu, et le filtre MUST NOT faire marquer lu un autre résumé.

#### Scenario: Activer le filtre
- **GIVEN** deux résumés non lus et trois lus
- **WHEN** l'utilisateur active « Non lus seulement »
- **THEN** la liste montre les deux non lus, plus le résumé affiché s'il est lu

#### Scenario: Lire sous le filtre
- **GIVEN** le filtre est actif
- **WHEN** l'utilisateur affiche un résumé non lu
- **THEN** il devient lu et reste dans la liste, et les autres non lus restent non lus

### Requirement: Tout marquer comme lu
Le système SHALL offrir dans la barre d'outils de la liste des résumés le bouton « Tout marquer comme lu » de la liste des articles, qui marque lus tous les résumés listés.

#### Scenario: Tout marquer
- **GIVEN** trois résumés non lus
- **WHEN** l'utilisateur clique sur « Tout marquer comme lu »
- **THEN** les trois sont lus et l'entrée « Résumés quotidiens » n'affiche plus de nombre

### Requirement: Mode sélection des résumés
Le système SHALL offrir dans la barre d'outils de la liste des résumés le bouton « Sélectionner » de la liste des articles : un clic coche ou décoche un résumé, le titre de la liste donne le nombre de cochés, le volet de lecture affiche ce nombre, et Échap ou le même bouton quittent le mode sans rien changer.

#### Scenario: Cocher des résumés
- **GIVEN** le mode sélection est actif
- **WHEN** l'utilisateur clique sur deux résumés
- **THEN** ils sont cochés, le titre indique « 2 sélectionnés » et le volet de lecture « 2 résumés sélectionnés »

#### Scenario: Quitter le mode
- **WHEN** l'utilisateur appuie sur Échap en mode sélection
- **THEN** les coches disparaissent et aucun résumé n'est modifié

### Requirement: Actions du volet de lecture des résumés
Le système SHALL offrir dans la barre d'outils du volet de lecture des résumés, à côté de la corbeille, le bouton « Marquer comme lu / non lu » du lecteur d'articles. Il agit sur le résumé affiché ou sur tous les résumés sélectionnés, et il est grisé quand il n'y en a aucun.

#### Scenario: Remettre en non lu le résumé affiché
- **GIVEN** le résumé affiché est lu
- **WHEN** l'utilisateur clique sur « Marquer comme non lu » dans la barre d'outils du volet
- **THEN** sa ligne reprend la pastille des non lus et il reste affiché

#### Scenario: Plusieurs résumés
- **GIVEN** trois résumés sélectionnés dont un non lu
- **WHEN** l'utilisateur clique sur « Marquer comme lu » dans la barre d'outils du volet
- **THEN** les trois sont lus

### Requirement: Nombre de résumés non lus
Le système SHALL afficher dans la barre latérale, sur l'entrée « Résumés quotidiens », le nombre de résumés non lus, et aucun nombre quand tous sont lus.

#### Scenario: Un nouveau résumé
- **GIVEN** tous les résumés sont lus
- **WHEN** un résumé est produit
- **THEN** l'entrée « Résumés quotidiens » affiche 1

#### Scenario: Tous lus
- **WHEN** l'utilisateur affiche le dernier résumé non lu
- **THEN** l'entrée « Résumés quotidiens » n'affiche plus de nombre
