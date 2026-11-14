# article-reading Specification

## Purpose

Permet de survoler rapidement les articles reçus, de les lire avec le contenu fourni par le flux ou dans le navigateur, et laisse s'effacer ce qui n'a pas été gardé.

## Requirements

### Requirement: Lister les articles
Le système SHALL afficher les articles de l'abonnement sélectionné, ou de tous les abonnements via une vue « Tous les articles », du plus récent au plus ancien. Chaque article MUST montrer son titre, sa source, sa date et s'il est lu ou non.

#### Scenario: Vue de tous les articles
- **WHEN** l'utilisateur sélectionne « Tous les articles »
- **THEN** les articles de tous les abonnements sont listés du plus récent au plus ancien

#### Scenario: Vue d'un abonnement
- **WHEN** l'utilisateur sélectionne un abonnement
- **THEN** seuls les articles de cet abonnement sont listés

### Requirement: Vue d'un dossier
Le système SHALL afficher, quand l'utilisateur sélectionne un dossier dans la barre latérale, les articles de tous les abonnements de ce dossier, du plus récent au plus ancien. Cette vue MUST offrir, comme celle d'un abonnement, la recherche, le filtre « Non lus » et sa propre sélection mémorisée.

#### Scenario: Sélection d'un dossier
- **WHEN** l'utilisateur sélectionne un dossier contenant deux abonnements
- **THEN** les articles des deux abonnements sont listés ensemble du plus récent au plus ancien, et aucun autre

#### Scenario: Recherche dans un dossier
- **WHEN** l'utilisateur recherche un mot dans la vue d'un dossier
- **THEN** seuls les articles des abonnements de ce dossier qui contiennent ce mot sont listés

#### Scenario: Mémoire du dossier
- **GIVEN** l'utilisateur a sélectionné un article dans la vue d'un dossier
- **WHEN** il ouvre une autre entrée puis revient sur ce dossier
- **THEN** le même article est de nouveau sélectionné

#### Scenario: Dossier vide
- **WHEN** l'utilisateur sélectionne un dossier sans abonnement
- **THEN** la liste est vide et aucun article n'est sélectionné

#### Scenario: Dossier supprimé
- **WHEN** le dossier affiché est supprimé
- **THEN** la vue « Tous les articles » est affichée

### Requirement: Compteur de non lus de « Tous les articles »
Le système SHALL afficher dans la barre latérale, à côté de « Tous les articles », le nombre d'articles non lus de cette liste, y compris les articles gardés dont l'abonnement a été supprimé. Ce nombre MUST NOT dépendre du filtre « Non lus ». Aucun nombre n'est affiché quand il n'y a aucun article non lu.

#### Scenario: Articles non lus
- **WHEN** la liste « Tous les articles » contient 7 articles non lus
- **THEN** « Tous les articles » affiche 7 dans la barre latérale

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur sélectionne lui-même un article non lu
- **THEN** le nombre de « Tous les articles » diminue de 1, comme celui de son abonnement

#### Scenario: Article gardé sans abonnement
- **GIVEN** un article gardé non lu dont l'abonnement a été supprimé
- **WHEN** l'utilisateur regarde la barre latérale
- **THEN** cet article est compté dans le nombre de « Tous les articles »

#### Scenario: Filtre « Non lus »
- **WHEN** l'utilisateur active ou désactive le filtre « Non lus »
- **THEN** le nombre de « Tous les articles » ne change pas

#### Scenario: Tout est lu
- **WHEN** aucun article n'est non lu
- **THEN** « Tous les articles » n'affiche aucun nombre

### Requirement: Filtrer les non lus
Le système SHALL permettre de n'afficher que les articles non lus dans la liste courante.

#### Scenario: Filtre activé
- **WHEN** l'utilisateur active le filtre « Non lus »
- **THEN** seuls les articles non lus de la liste courante sont affichés

### Requirement: Rechercher dans la liste courante
Le système SHALL proposer un champ de recherche dans toutes les vues de la barre latérale (« Tous les articles », chaque abonnement, Cairn et chaque tag). Il MUST limiter la liste aux articles dont le titre, le contenu, la note ou un tag contient le texte recherché, sans tenir compte de la casse ni des accents. Le raccourci ⌘F MUST placer le curseur dans ce champ.

#### Scenario: Recherche dans « Tous les articles »
- **WHEN** l'utilisateur recherche un mot présent dans le titre d'un article non gardé de « Tous les articles »
- **THEN** cet article figure dans les résultats, et les articles qui ne contiennent pas ce mot n'y figurent pas

#### Scenario: Recherche dans un abonnement
- **WHEN** l'utilisateur recherche un mot dans la vue d'un abonnement
- **THEN** seuls les articles de cet abonnement qui contiennent ce mot sont listés

#### Scenario: Recherche dans une note
- **WHEN** l'utilisateur recherche un mot qui n'apparaît que dans la note d'un article gardé
- **THEN** cet article figure dans les résultats

#### Scenario: Recherche sans accent
- **WHEN** l'utilisateur recherche « deploiement » et qu'un article de la liste contient « Déploiement »
- **THEN** cet article figure dans les résultats

#### Scenario: Recherche et filtre « Non lus »
- **WHEN** le filtre « Non lus » est actif et que l'utilisateur recherche un mot
- **THEN** seuls les articles non lus qui contiennent ce mot sont listés

#### Scenario: Raccourci ⌘F
- **WHEN** l'utilisateur appuie sur ⌘F, quelle que soit la vue affichée
- **THEN** le curseur est placé dans le champ de recherche de cette vue, sans changer de vue

#### Scenario: Changement d'entrée
- **WHEN** l'utilisateur change d'entrée dans la barre latérale après une recherche
- **THEN** le champ de recherche est vide et la nouvelle liste est complète

### Requirement: Surligner le terme recherché
Pendant une recherche, le système SHALL surligner le terme recherché dans la liste et dans l'article affiché, selon la même règle que la recherche (sans tenir compte de la casse ni des accents). Une ligne dont le titre ne contient pas le terme MUST afficher un court extrait autour de sa première occurrence dans le contenu, la note ou les tags. Le surlignage MUST NOT exécuter de script de l'article.

#### Scenario: Terme dans le titre
- **WHEN** l'utilisateur recherche un mot présent dans le titre d'un article
- **THEN** ce mot est surligné dans le titre de la ligne, sans extrait supplémentaire

#### Scenario: Terme hors du titre
- **WHEN** l'utilisateur recherche un mot présent dans le contenu, la note ou un tag d'un article, mais pas dans son titre
- **THEN** la ligne affiche sous le titre un court extrait autour de la première occurrence, mot surligné

#### Scenario: Surlignage sans accent
- **WHEN** l'utilisateur recherche « deploiement » et qu'un article contient « Déploiement »
- **THEN** « Déploiement » est surligné

#### Scenario: Article affiché
- **WHEN** l'utilisateur affiche un article pendant une recherche
- **THEN** toutes les occurrences du terme sont surlignées dans son titre et son contenu, et le contenu défile jusqu'à la première

#### Scenario: Fin de la recherche
- **WHEN** l'utilisateur efface le texte recherché
- **THEN** le surlignage et les extraits disparaissent de la liste et de l'article

### Requirement: Afficher un article
Le système SHALL afficher le titre, la source, la date et le contenu fourni par le flux de l'article sélectionné, mis en forme (HTML rendu). Le contenu MUST être affiché sans exécuter de script ni charger de contenu distant autre que les images.

#### Scenario: Sélection d'un article
- **WHEN** l'utilisateur sélectionne un article
- **THEN** son contenu s'affiche dans le panneau de lecture

#### Scenario: Article sans contenu
- **WHEN** l'article sélectionné n'a ni contenu ni résumé dans le flux
- **THEN** le panneau indique qu'aucun contenu n'est disponible et propose de l'ouvrir dans le navigateur

### Requirement: Taille du texte de l'article
Le système SHALL permettre d'agrandir, de réduire et de rétablir la taille du texte du panneau de lecture depuis le menu Présentation (⌘+, ⌘−, ⌘0) et depuis la section « Affichage » des Réglages, sur tous les appareils. La taille MUST s'appliquer au titre, à la ligne source et date et au contenu de l'article, rester entre un minimum et un maximum, et être conservée d'un lancement à l'autre.

#### Scenario: Agrandir le texte
- **WHEN** l'utilisateur choisit « Agrandir le texte » ou appuie sur ⌘+
- **THEN** le titre, la ligne source et date et le contenu de l'article affiché grandissent ensemble

#### Scenario: Taille normale
- **WHEN** l'utilisateur choisit « Taille normale » ou appuie sur ⌘0
- **THEN** le panneau de lecture revient à la taille par défaut

#### Scenario: Limite atteinte
- **WHEN** la taille maximale est atteinte
- **THEN** « Agrandir le texte » est indisponible et la taille ne change plus (et de même pour « Réduire le texte » au minimum)

#### Scenario: Depuis les Réglages
- **WHEN** l'utilisateur touche « + » sur la ligne « Taille du texte » des Réglages
- **THEN** le pourcentage affiché augmente et l'article affiché grandit d'autant

#### Scenario: Changement d'article et relancement
- **WHEN** l'utilisateur a agrandi le texte puis affiche un autre article ou relance l'application
- **THEN** le nouvel article s'affiche avec la taille choisie

### Requirement: Sélection d'article par défaut
Quand une entrée de la barre latérale (« Tous les articles », « Cairn », un tag, un dossier ou un abonnement) est affichée sans article mémorisé visible dans sa liste, le système SHALL n'afficher aucun article : aucune ligne n'est sélectionnée et le volet de lecture indique qu'aucun article n'est sélectionné, avec ses boutons grisés.

#### Scenario: Premier lancement
- **WHEN** l'utilisateur lance l'app pour la première fois et que « Tous les articles » contient des articles
- **THEN** aucun article n'est sélectionné et le volet de lecture indique « Aucun article sélectionné »

#### Scenario: Entrée jamais ouverte
- **WHEN** l'utilisateur sélectionne un abonnement dont aucun article n'a encore été sélectionné
- **THEN** ses articles sont listés sans qu'aucun soit sélectionné ni affiché

#### Scenario: Liste vide
- **WHEN** l'utilisateur sélectionne une entrée dont la liste ne contient aucun article
- **THEN** aucun article n'est sélectionné et le panneau de lecture indique qu'aucun article n'est sélectionné

### Requirement: Sélection mémorisée par entrée
Le système SHALL retenir, pour chaque entrée de la barre latérale, le dernier article sélectionné, et le sélectionner de nouveau quand l'utilisateur revient sur cette entrée. Chaque abonnement et chaque tag a sa propre mémoire.

#### Scenario: Retour sur « Tous les articles »
- **GIVEN** l'utilisateur a sélectionné le troisième article de « Tous les articles »
- **WHEN** il ouvre « Cairn » ou un abonnement, puis revient sur « Tous les articles »
- **THEN** le troisième article est de nouveau sélectionné et affiché

#### Scenario: Mémoires indépendantes
- **GIVEN** l'utilisateur a sélectionné l'article A dans l'abonnement X et l'article B dans l'abonnement Y
- **WHEN** il revient sur l'abonnement X
- **THEN** l'article A est sélectionné

#### Scenario: Article mémorisé absent de la liste
- **GIVEN** l'article mémorisé d'une entrée n'est plus dans sa liste (filtre « Non lus », recherche, purge, suppression ou désabonnement)
- **WHEN** l'utilisateur revient sur cette entrée
- **THEN** aucun article n'est sélectionné et le volet de lecture indique « Aucun article sélectionné »

### Requirement: Sélection conservée entre les lancements
Le système SHALL conserver d'un lancement à l'autre l'entrée de la barre latérale affichée et l'article mémorisé de chaque entrée. Cette mémoire est propre à l'appareil.

#### Scenario: Relancement
- **GIVEN** l'utilisateur lisait l'article A de l'abonnement X
- **WHEN** il quitte puis relance l'app
- **THEN** l'abonnement X est affiché avec l'article A sélectionné

#### Scenario: Entrée disparue
- **GIVEN** l'entrée affichée au moment de quitter n'existe plus au relancement (abonnement supprimé, tag disparu)
- **WHEN** l'utilisateur relance l'app
- **THEN** « Tous les articles » est affiché

### Requirement: État lu / non lu
Le système SHALL marquer un article comme lu quand l'utilisateur le sélectionne lui-même (clic ou clavier) et qu'il est le seul article sélectionné, et MUST permettre de le remettre manuellement en non lu ou en lu, ou de marquer tous les articles de la liste courante comme lus. Un article sélectionné automatiquement (sélection mémorisée) ou faisant partie d'une sélection de plusieurs articles MUST être affiché ou sélectionné sans que son état lu change.

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur sélectionne lui-même un article non lu
- **THEN** l'article est marqué lu et le compteur de non lus de son abonnement diminue

#### Scenario: Sélection automatique
- **WHEN** un article non lu mémorisé est sélectionné de nouveau à l'ouverture d'une entrée ou au lancement
- **THEN** il est affiché et reste non lu

#### Scenario: Filtre « Non lus » et sélection automatique
- **WHEN** le filtre « Non lus » est actif et que l'article non lu mémorisé est sélectionné de nouveau à l'ouverture de l'entrée
- **THEN** il reste non lu et visible dans la liste, et aucun autre article n'est marqué lu

#### Scenario: Tout marquer comme lu
- **WHEN** l'utilisateur choisit « Tout marquer comme lu » sur la liste courante
- **THEN** tous les articles de cette liste deviennent lus

#### Scenario: Sélection multiple
- **WHEN** l'utilisateur sélectionne trois articles non lus au ⌘-clic
- **THEN** les trois restent non lus

#### Scenario: Basculer l'article affiché
- **GIVEN** l'article affiché est lu
- **WHEN** l'utilisateur choisit « Marquer comme non lu » dans la barre d'outils, puis le même bouton, devenu « Marquer comme lu »
- **THEN** l'article redevient non lu, puis de nouveau lu

### Requirement: Ouvrir dans le navigateur
Le système SHALL permettre d'ouvrir le lien de l'article dans le navigateur par défaut.

#### Scenario: Ouverture
- **WHEN** l'utilisateur demande à ouvrir l'article dans le navigateur
- **THEN** le navigateur par défaut s'ouvre sur le lien de l'article

### Requirement: Purger les articles non gardés
Le système SHALL supprimer automatiquement, au lancement, les articles non gardés dont la date de publication dépasse la durée de conservation réglée (« Conserver les articles non gardés » : 7, 14 ou 30 jours, 2, 3 ou 6 mois, 1 an ; 30 jours par défaut). Les articles gardés MUST NOT être purgés.

#### Scenario: Article ancien non gardé
- **GIVEN** la durée de conservation est de 30 jours
- **WHEN** l'application démarre et qu'un article non gardé a plus de 30 jours
- **THEN** cet article est supprimé

#### Scenario: Article ancien gardé
- **WHEN** l'application démarre et qu'un article gardé dépasse la durée de conservation
- **THEN** cet article est conservé

#### Scenario: Durée allongée
- **GIVEN** la durée de conservation est de 3 mois
- **WHEN** l'application démarre et qu'un article non gardé a 45 jours
- **THEN** cet article est conservé

### Requirement: Sélectionner plusieurs articles
Le système SHALL permettre de sélectionner plusieurs articles dans toute liste d'articles avec les gestes standard du Mac : ⌘-clic pour ajouter ou retirer un article, ⇧-clic ou ⇧-flèche pour étendre la sélection, ⌘A pour tout sélectionner. Une action choisie dans le menu contextuel d'un article sélectionné MUST s'appliquer à toute la sélection ; sur un article non sélectionné, elle ne porte que sur lui.

#### Scenario: Sélection au ⌘-clic
- **GIVEN** un article est sélectionné
- **WHEN** l'utilisateur ⌘-clique sur deux autres articles
- **THEN** les trois articles sont sélectionnés

#### Scenario: Tout sélectionner
- **WHEN** l'utilisateur appuie sur ⌘A dans une liste de vingt articles
- **THEN** les vingt articles sont sélectionnés

#### Scenario: Menu contextuel sur la sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur fait un clic droit sur l'un d'eux et choisit une action
- **THEN** l'action s'applique aux trois articles

#### Scenario: Menu contextuel hors de la sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur fait un clic droit sur un quatrième article et choisit une action
- **THEN** l'action ne s'applique qu'à ce quatrième article

### Requirement: Volet de lecture d'une sélection multiple
Le système SHALL, quand plusieurs articles sont sélectionnés ou en mode sélection, afficher dans le volet de lecture le nombre d'articles sélectionnés (« N articles sélectionnés ») au lieu d'un article. Les actions sur la sélection MUST être dans la barre d'outils du volet de lecture, aux mêmes places que pour un seul article, et aucune barre d'actions ne s'affiche sous la liste.

#### Scenario: Plusieurs articles sélectionnés
- **WHEN** l'utilisateur sélectionne trois articles
- **THEN** le volet de lecture affiche « 3 articles sélectionnés », les actions sur la sélection sont actives dans sa barre d'outils, et rien ne recouvre la liste

#### Scenario: Retour à un seul article
- **GIVEN** trois articles sont sélectionnés au ⌘-clic, hors du mode sélection
- **WHEN** l'utilisateur clique sur un seul article sans touche de modification
- **THEN** cet article est affiché comme d'habitude

### Requirement: Barre d'outils du volet sans article
Le système SHALL, quand le volet de lecture n'affiche pas un article (aucun article sélectionné, sélection multiple ou mode sélection), garder les boutons de lecture à leur place, comme Mail. Avec au moins un article sélectionné, Garder, Marquer et Ouvrir dans le navigateur MUST être actifs et porter sur la sélection ; Partager MUST être actif pour un seul article sélectionné ; les autres boutons, dont l'inspecteur, sont grisés.

#### Scenario: Entrer en mode sélection
- **GIVEN** un article est affiché dans le volet de lecture
- **WHEN** l'utilisateur active le mode sélection
- **THEN** les boutons de lecture restent à leur place et ceux de la liste ne bougent pas

#### Scenario: Aucun article sélectionné
- **WHEN** le volet de lecture indique « Aucun article sélectionné »
- **THEN** les boutons Article complet, Résumer, Garder, Marquer, Partager, Ouvrir dans le navigateur et Inspecteur sont à leur place, tous grisés

#### Scenario: Actions d'une sélection
- **GIVEN** trois articles sont sélectionnés
- **WHEN** l'utilisateur regarde la barre d'outils du volet de lecture
- **THEN** Garder, Marquer comme lu et Ouvrir dans le navigateur sont actifs, et Article complet, Résumer, Partager et Inspecteur sont grisés

#### Scenario: Un seul article coché
- **GIVEN** le mode sélection est actif et un seul article est coché
- **WHEN** l'utilisateur choisit Partager dans la barre d'outils du volet de lecture
- **THEN** la feuille de partage s'ouvre avec le titre et le lien de cet article

### Requirement: Marquer plusieurs articles comme lus ou non lus
Le système SHALL permettre de marquer toute la sélection comme lue ou non lue. Quand au moins un article de la sélection est non lu, l'action proposée MUST être « Marquer comme lu » ; sinon « Marquer comme non lu ».

#### Scenario: Sélection en partie non lue
- **GIVEN** deux articles lus et un non lu sont sélectionnés
- **WHEN** l'utilisateur choisit « Marquer comme lu »
- **THEN** les trois articles sont lus

#### Scenario: Sélection entièrement lue
- **GIVEN** trois articles lus sont sélectionnés
- **WHEN** l'utilisateur choisit « Marquer comme non lu »
- **THEN** les trois articles redeviennent non lus et les compteurs augmentent de trois

### Requirement: Ouvrir plusieurs articles dans le navigateur
Le système SHALL permettre d'ouvrir le lien de chaque article sélectionné dans le navigateur par défaut. Au-delà de 10 articles, le système MUST demander confirmation avant de les ouvrir.

#### Scenario: Ouvrir trois articles
- **WHEN** l'utilisateur choisit « Ouvrir dans le navigateur » avec trois articles sélectionnés
- **THEN** les trois liens s'ouvrent dans le navigateur

#### Scenario: Ouvrir beaucoup d'articles
- **WHEN** l'utilisateur choisit « Ouvrir dans le navigateur » avec quinze articles sélectionnés
- **THEN** le système demande confirmation avant d'ouvrir les quinze liens

### Requirement: Sélection multiple non mémorisée
Le système MUST NOT retenir une sélection multiple, ni par entrée ni d'un lancement à l'autre : seule une sélection d'un article est mémorisée. Quitter une entrée avec plusieurs articles sélectionnés MUST laisser sa mémoire telle qu'elle était avant la sélection multiple.

#### Scenario: Revenir sur l'entrée
- **GIVEN** l'utilisateur avait l'article A sélectionné dans un abonnement, puis a sélectionné trois articles
- **WHEN** il ouvre une autre entrée puis revient sur cet abonnement
- **THEN** seul l'article A est sélectionné

### Requirement: Mode sélection
Le système SHALL proposer dans la barre d'outils de la liste d'articles un bouton « Sélectionner » qui passe la liste en mode sélection : chaque ligne montre une case, et un clic ou un toucher sur une ligne l'ajoute à la sélection ou l'en retire. Sur Mac, ⌘-clic et ⇧-clic restent disponibles et passent aussi en mode sélection dès que plusieurs articles sont sélectionnés. Quitter le mode (bouton ou Échap) MUST vider la sélection.

#### Scenario: Cocher des articles
- **GIVEN** l'utilisateur a activé le mode sélection
- **WHEN** il clique sur deux articles puis de nouveau sur le premier
- **THEN** seul le second article est sélectionné et coché

#### Scenario: Quitter sans action
- **GIVEN** trois articles sont cochés en mode sélection
- **WHEN** l'utilisateur touche de nouveau « Sélectionner » ou appuie sur Échap
- **THEN** le mode sélection se termine et aucun article ne reste sélectionné

### Requirement: Titre et actions d'une sélection
Le système SHALL, en mode sélection, remplacer le titre de la liste par le nombre d'articles sélectionnés (« Aucune sélection », « 1 sélectionné », « N sélectionnés ») et proposer les actions sur la sélection dans la barre d'outils du volet de lecture. La suppression d'articles qui n'ont plus d'abonnement MUST rester disponible par le menu contextuel et la touche Supprimer. Sans article sélectionné, ces actions MUST être inactives.

#### Scenario: Trois articles cochés
- **WHEN** l'utilisateur coche trois articles en mode sélection
- **THEN** le titre de la liste devient « 3 sélectionnés » et les actions sont actives dans la barre d'outils du volet de lecture

#### Scenario: Aucune sélection
- **WHEN** l'utilisateur active le mode sélection sans cocher d'article
- **THEN** le titre affiche « Aucune sélection » et les actions du volet de lecture sont inactives

#### Scenario: Supprimer des articles sans abonnement
- **GIVEN** deux articles dont l'abonnement a été supprimé sont cochés
- **WHEN** l'utilisateur appuie sur la touche Supprimer ou choisit « Supprimer 2 articles… » dans le menu contextuel
- **THEN** le système demande confirmation avant de les supprimer

### Requirement: Marquer un abonnement ou un dossier comme lu
Le système SHALL proposer « Marquer tout comme lu » dans le menu contextuel d'un ou plusieurs abonnements et dans celui d'un dossier de la barre latérale. L'action MUST marquer comme lus tous les articles de ces abonnements, ou de tous les abonnements du dossier, sans changer l'entrée affichée. Elle MUST être grisée quand ils n'ont aucun article non lu.

#### Scenario: Abonnement avec des non lus
- **GIVEN** un abonnement a trois articles non lus
- **WHEN** l'utilisateur choisit « Marquer tout comme lu » dans son menu contextuel
- **THEN** ses trois articles sont lus et son compteur de non lus disparaît, ainsi que leur part dans les autres compteurs

#### Scenario: Dossier
- **GIVEN** un dossier contient deux abonnements ayant chacun des articles non lus
- **WHEN** l'utilisateur choisit « Marquer tout comme lu » dans le menu contextuel du dossier
- **THEN** tous les articles des deux abonnements sont lus

#### Scenario: Rien à marquer
- **WHEN** l'utilisateur ouvre le menu contextuel d'un abonnement sans article non lu
- **THEN** « Marquer tout comme lu » est grisé

### Requirement: Menu Article
Le système SHALL proposer dans la barre des menus un menu « Article » avec les mêmes actions, dans le même ordre, que le menu contextuel d'un article. Elles MUST porter sur l'article affiché ou sur les articles sélectionnés, et être grisées sans liste d'articles affichée. Garder MUST avoir le raccourci ⇧⌘L, Marquer comme lu ou non lu ⇧⌘U, et Ouvrir dans le navigateur ⌘↩.

#### Scenario: Basculer au clavier
- **GIVEN** un article lu est affiché
- **WHEN** l'utilisateur appuie sur ⇧⌘U, puis de nouveau sur ⇧⌘U
- **THEN** l'article redevient non lu, puis de nouveau lu

#### Scenario: Sélection multiple
- **GIVEN** trois articles non lus sont sélectionnés
- **WHEN** l'utilisateur choisit Article > Marquer comme lu
- **THEN** les trois articles sont lus

#### Scenario: Pas de liste d'articles
- **WHEN** « Résumés quotidiens » est affiché
- **THEN** les actions du menu « Article » sont grisées

### Requirement: Badge des non-lus sur l'icône du Dock
Le système SHALL afficher sur l'icône du Dock le nombre d'articles non lus, le même que celui de « Tous les articles », fenêtre ouverte ou fermée. Aucun badge n'est affiché quand il n'y a aucun article non lu.

#### Scenario: Articles non lus
- **WHEN** la liste « Tous les articles » contient 7 articles non lus
- **THEN** l'icône de Cairn dans le Dock affiche 7

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur lit un article non lu
- **THEN** le badge diminue de 1

#### Scenario: Nouveaux articles fenêtre fermée
- **GIVEN** l'application tourne sans fenêtre ouverte
- **WHEN** un rafraîchissement apporte 3 nouveaux articles
- **THEN** le badge augmente de 3

#### Scenario: Tout est lu
- **WHEN** aucun article n'est non lu
- **THEN** l'icône du Dock n'affiche aucun badge

### Requirement: Réglage du badge
Le système SHALL proposer dans la section Affichage des Réglages un interrupteur « Badge sur l'icône », activé par défaut. Désactivé, l'icône du Dock MUST NOT afficher de badge. macOS n'affiche le badge qu'avec l'autorisation des pastilles : quand l'interrupteur est activé, le système MUST la demander, et MUST signaler dans les Réglages qu'elle a été refusée.

#### Scenario: Premier lancement
- **WHEN** l'utilisateur lance l'application pour la première fois
- **THEN** macOS demande l'autorisation des notifications de Cairn, pastilles comprises

#### Scenario: Pastilles refusées
- **GIVEN** les pastilles de Cairn sont désactivées dans Réglages Système
- **WHEN** l'utilisateur ouvre les Réglages avec « Badge sur l'icône » activé
- **THEN** un texte indique que les pastilles sont désactivées et comment les autoriser

#### Scenario: Désactiver le badge
- **WHEN** l'utilisateur désactive « Badge sur l'icône »
- **THEN** le badge disparaît aussitôt de l'icône du Dock

#### Scenario: Réactiver le badge
- **WHEN** l'utilisateur réactive « Badge sur l'icône » alors que 7 articles sont non lus
- **THEN** l'icône du Dock affiche 7 aussitôt

### Requirement: Aller au prochain non lu
Le système SHALL ouvrir, quand la liste d'articles a le focus et que l'utilisateur appuie sur Espace ou N, le prochain article non lu de la liste affichée après l'article courant, en reprenant en haut après le dernier. L'article ouvert MUST être marqué comme lu et rendu visible dans la liste. Sans article non lu, le système MUST émettre le son d'alerte et ne rien changer.

#### Scenario: Article non lu plus bas
- **GIVEN** l'article courant est le deuxième de la liste et le cinquième est le premier non lu après lui
- **WHEN** l'utilisateur appuie sur Espace
- **THEN** le cinquième article s'affiche, marqué comme lu, et la liste défile jusqu'à lui

#### Scenario: Reprise en haut
- **GIVEN** aucun article non lu après l'article courant, mais un non lu plus haut
- **WHEN** l'utilisateur appuie sur N
- **THEN** ce non lu plus haut s'affiche

#### Scenario: Tout est lu
- **WHEN** l'utilisateur appuie sur Espace et qu'aucun article de la liste n'est non lu
- **THEN** le son d'alerte retentit et l'article courant reste affiché

#### Scenario: Espace dans l'article
- **WHEN** le focus est dans l'article affiché et que l'utilisateur appuie sur Espace
- **THEN** l'article défile, sans changer d'article

### Requirement: Ordre des articles
Le système SHALL proposer dans le menu Présentation « Ordre des articles » : « Plus récents d'abord » (par défaut) ou « Plus anciens d'abord ». Le choix MUST s'appliquer à toutes les listes d'articles et être conservé entre les lancements.

#### Scenario: Plus anciens d'abord
- **WHEN** l'utilisateur choisit « Plus anciens d'abord »
- **THEN** la liste affichée commence par l'article le plus ancien

#### Scenario: Cairn
- **GIVEN** l'ordre est « Plus anciens d'abord »
- **WHEN** l'utilisateur affiche un cairn
- **THEN** ses articles commencent par le premier gardé

### Requirement: Vue « Aujourd'hui »
Le système SHALL proposer dans la barre latérale, sous « Tous les articles », une entrée « Aujourd'hui » qui affiche les articles de tous les abonnements publiés depuis minuit (heure locale), avec à côté le nombre de ces articles non lus, sans nombre quand il n'y en a aucun. Cette vue MUST se comporter comme « Tous les articles » pour la recherche, le filtre « Non lus », l'ordre et le prochain non lu.

#### Scenario: Articles du jour
- **GIVEN** un article publié ce matin et un autre hier soir
- **WHEN** l'utilisateur sélectionne « Aujourd'hui »
- **THEN** seul l'article de ce matin est affiché

#### Scenario: Compteur
- **GIVEN** trois articles publiés aujourd'hui, dont deux non lus
- **WHEN** l'utilisateur regarde la barre latérale
- **THEN** « Aujourd'hui » affiche 2

### Requirement: Écouter un épisode de podcast
Le système SHALL retenir, à l'import, le fichier audio joint à un article (enclosure RSS, lien Atom « enclosure », pièce jointe JSON Feed) et afficher sous l'en-tête de cet article le lecteur audio du système. La lecture MUST s'arrêter quand l'utilisateur change d'article. Un article sans audio MUST NOT afficher de lecteur.

#### Scenario: Épisode avec audio
- **GIVEN** un flux dont un article joint `episode.mp3` de type `audio/mpeg`
- **WHEN** l'utilisateur ouvre cet article
- **THEN** un lecteur permet d'écouter `episode.mp3`

#### Scenario: Article sans audio
- **WHEN** l'utilisateur ouvre un article sans fichier audio joint
- **THEN** aucun lecteur n'est affiché

### Requirement: Masquer les doublons
Le système SHALL n'afficher qu'un article par lien normalisé dans les listes qui réunissent plusieurs abonnements : « Tous les articles », « Aujourd'hui », la vue d'un dossier et la sélection de plusieurs abonnements, y compris pendant une recherche ou avec le filtre « Non lus ». L'article affiché MUST être, dans cet ordre, un exemplaire gardé, sinon un exemplaire non lu, sinon le plus récent. La vue d'un abonnement et les vues de cairn et de tag MUST continuer d'afficher tous leurs articles.

#### Scenario: Liste de tous les articles
- **GIVEN** le même lien est arrivé par « Blog » et par « Agrégateur »
- **WHEN** l'utilisateur ouvre « Tous les articles »
- **THEN** une seule ligne montre cet article

#### Scenario: Vue d'un abonnement
- **GIVEN** le même lien est arrivé par « Blog » et par « Agrégateur »
- **WHEN** l'utilisateur ouvre « Agrégateur »
- **THEN** l'exemplaire d'« Agrégateur » est listé

#### Scenario: Exemplaire gardé
- **GIVEN** l'exemplaire d'« Agrégateur » est gardé et celui de « Blog » ne l'est pas
- **WHEN** l'utilisateur ouvre « Tous les articles »
- **THEN** la ligne affichée est l'exemplaire gardé, avec sa marque de cairn
