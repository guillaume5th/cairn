# daily-digest Specification

## Purpose

Résume chaque jour, à l'heure choisie et par une IA qui tourne sur la machine, les articles reçus dans les dernières 24 heures, et garde ces résumés quelques jours.

## Requirements

### Requirement: Heure du résumé quotidien
Le système SHALL produire un résumé par jour à l'heure réglée par l'utilisateur, 8 h par défaut. Le réglage MUST être conservé sur ce Mac entre les lancements. Le résumé est produit pendant que l'app est ouverte ; aucun processus ne tourne quand elle est fermée.

#### Scenario: Heure atteinte app ouverte
- **GIVEN** l'heure du résumé est 8 h et aucun résumé n'a encore été tenté aujourd'hui
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** un résumé est produit dans la minute

#### Scenario: Changement de l'heure
- **GIVEN** le résumé d'aujourd'hui n'a pas encore été tenté
- **WHEN** l'utilisateur règle l'heure sur un moment déjà passé aujourd'hui
- **THEN** le résumé d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Une seule tentative automatique par jour
- **GIVEN** le résumé d'aujourd'hui a déjà été tenté, avec succès ou non
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun autre résumé automatique n'est lancé avant le lendemain

### Requirement: Rattrapage au lancement
Le système SHALL produire au lancement le résumé du jour quand l'heure réglée est passée et qu'aucun résumé n'a été tenté depuis.

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
Le système SHALL proposer deux moteurs qui tournent sur la machine : le modèle d'Apple intégré au système (par défaut) et un serveur Ollama local dont l'adresse (http://localhost:11434 par défaut) et le nom du modèle se règlent. Le contenu des articles MUST NOT être envoyé à un autre service.

#### Scenario: Moteur Apple
- **GIVEN** le moteur choisi est celui d'Apple et il est disponible sur ce Mac
- **WHEN** le résumé est produit
- **THEN** il est rédigé par le modèle d'Apple, sans accès réseau

#### Scenario: Moteur Ollama
- **GIVEN** le moteur choisi est Ollama avec le modèle « llama3.2 »
- **WHEN** le résumé est produit
- **THEN** il est rédigé par ce modèle via le serveur Ollama réglé

### Requirement: Échec du résumé
Le système SHALL, quand le moteur est indisponible ou échoue, n'enregistrer aucun résumé et afficher un message qui dit pourquoi (par exemple : Apple Intelligence désactivé, serveur Ollama injoignable, modèle introuvable). L'échec compte comme la tentative du jour.

#### Scenario: Ollama arrêté
- **GIVEN** le moteur choisi est Ollama et le serveur ne répond pas
- **WHEN** l'heure du résumé arrive
- **THEN** un message indique que le serveur Ollama est injoignable, aucun résumé n'est enregistré, et aucune nouvelle tentative automatique n'a lieu ce jour-là

#### Scenario: Modèle d'Apple indisponible
- **GIVEN** le moteur choisi est celui d'Apple et Apple Intelligence n'est pas disponible sur ce Mac
- **WHEN** le résumé est produit
- **THEN** un message en donne la raison et aucun résumé n'est enregistré

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
Le système SHALL afficher, quand l'utilisateur sélectionne l'entrée « Résumés » de la barre latérale, la liste des résumés du plus récent au plus ancien, chacun désigné par sa date et son heure ; le résumé sélectionné s'affiche dans le volet de lecture.

#### Scenario: Ouvrir un résumé
- **WHEN** l'utilisateur sélectionne l'entrée « Résumés » puis un résumé
- **THEN** son texte et la liste de ses articles s'affichent dans le volet de lecture

#### Scenario: Aucun résumé
- **WHEN** l'utilisateur sélectionne l'entrée « Résumés » alors qu'il n'y a aucun résumé
- **THEN** la liste est vide et le volet indique l'heure du prochain résumé

### Requirement: Supprimer un résumé
Le système SHALL permettre de supprimer un résumé depuis la liste des résumés, par le bouton corbeille au-dessus du résumé affiché, son menu contextuel ou la touche Supprimer, après confirmation. La suppression MUST être définitive et ne touche ni les articles ni la date de la dernière tentative.

#### Scenario: Supprimer le résumé sélectionné
- **GIVEN** deux résumés sont listés et le plus récent est sélectionné
- **WHEN** l'utilisateur choisit « Supprimer le résumé… » puis confirme
- **THEN** ce résumé disparaît et l'autre s'affiche dans le volet de lecture

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
Le système SHALL offrir une fenêtre Réglages (⌘,) qui permet de régler l'heure du résumé, le moteur, l'adresse et le modèle Ollama, et la durée de conservation. Les réglages Ollama MUST n'être affichés que lorsque le moteur Ollama est choisi.

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
