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
Le système SHALL afficher, quand l'utilisateur sélectionne un dossier dans la barre latérale, les articles de tous les abonnements de ce dossier, du plus récent au plus ancien. Cette vue MUST offrir, comme celle d'un abonnement, la recherche, le filtre « Non lus », la sélection par défaut et sa propre sélection mémorisée.

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
Quand une entrée de la barre latérale (« Tous les articles », « Cairn », un tag ou un abonnement) est affichée sans article mémorisé visible dans sa liste, le système SHALL sélectionner et afficher le premier article de la liste. Si la liste est vide, aucun article n'est sélectionné.

#### Scenario: Premier lancement
- **WHEN** l'utilisateur lance l'app pour la première fois et que « Tous les articles » contient des articles
- **THEN** le premier article de la liste est sélectionné et affiché dans le panneau de lecture

#### Scenario: Entrée jamais ouverte
- **WHEN** l'utilisateur sélectionne un abonnement dont aucun article n'a encore été sélectionné
- **THEN** le premier article de cet abonnement est sélectionné et affiché

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
- **THEN** le premier article de la liste est sélectionné

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
Le système SHALL marquer un article comme lu quand l'utilisateur le sélectionne lui-même (clic ou clavier) et qu'il est le seul article sélectionné, et MUST permettre de le remettre manuellement en non lu ou de marquer tous les articles de la liste courante comme lus. Un article sélectionné automatiquement (sélection par défaut ou mémorisée) ou faisant partie d'une sélection de plusieurs articles MUST être affiché ou sélectionné sans que son état lu change.

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur sélectionne lui-même un article non lu
- **THEN** l'article est marqué lu et le compteur de non lus de son abonnement diminue

#### Scenario: Sélection automatique
- **WHEN** un article non lu est sélectionné automatiquement à l'ouverture d'une entrée ou au lancement
- **THEN** il est affiché et reste non lu

#### Scenario: Filtre « Non lus » et sélection automatique
- **WHEN** le filtre « Non lus » est actif et que le premier article est sélectionné automatiquement
- **THEN** il reste non lu et visible dans la liste, et aucun autre article n'est marqué lu

#### Scenario: Tout marquer comme lu
- **WHEN** l'utilisateur choisit « Tout marquer comme lu » sur la liste courante
- **THEN** tous les articles de cette liste deviennent lus

#### Scenario: Sélection multiple
- **WHEN** l'utilisateur sélectionne trois articles non lus au ⌘-clic
- **THEN** les trois restent non lus

### Requirement: Ouvrir dans le navigateur
Le système SHALL permettre d'ouvrir le lien de l'article dans le navigateur par défaut.

#### Scenario: Ouverture
- **WHEN** l'utilisateur demande à ouvrir l'article dans le navigateur
- **THEN** le navigateur par défaut s'ouvre sur le lien de l'article

### Requirement: Purger les articles non gardés
Le système SHALL supprimer automatiquement les articles non gardés dont la date de publication remonte à plus de 30 jours. Les articles gardés MUST NOT être purgés.

#### Scenario: Article ancien non gardé
- **WHEN** l'application démarre et qu'un article non gardé a plus de 30 jours
- **THEN** cet article est supprimé

#### Scenario: Article ancien gardé
- **WHEN** l'application démarre et qu'un article gardé a plus de 30 jours
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
Le système SHALL, quand plusieurs articles sont sélectionnés ou en mode sélection, afficher dans le volet de lecture le nombre d'articles sélectionnés (« N articles sélectionnés ») au lieu d'un article. Les actions sur la sélection MUST être sous la liste sur tous les appareils, pas dans le volet.

#### Scenario: Plusieurs articles sélectionnés
- **WHEN** l'utilisateur sélectionne trois articles
- **THEN** le volet de lecture affiche « 3 articles sélectionnés », et les actions sur la sélection sont proposées sous la liste

#### Scenario: Retour à un seul article
- **GIVEN** trois articles sont sélectionnés au ⌘-clic, hors du mode sélection
- **WHEN** l'utilisateur clique sur un seul article sans touche de modification
- **THEN** cet article est affiché comme d'habitude

### Requirement: Barre d'outils du volet sans article
Le système SHALL, quand le volet de lecture n'affiche pas un article (aucun article sélectionné, sélection multiple ou mode sélection), y garder les boutons de lecture (Résumer, Garder, Marquer comme non lu, Ouvrir dans le navigateur) grisés, comme Mail, pour que la barre d'outils ne change pas de disposition.

#### Scenario: Entrer en mode sélection
- **GIVEN** un article est affiché dans le volet de lecture
- **WHEN** l'utilisateur active le mode sélection
- **THEN** les boutons de lecture restent à leur place, grisés, et ceux de la liste ne bougent pas

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
Le système SHALL, en mode sélection sur Mac, iPhone et iPad, remplacer le titre de la liste par le nombre d'articles sélectionnés (« Aucune sélection », « 1 sélectionné », « N sélectionnés ») et afficher sous la liste les actions qui s'appliquent à la sélection : garder dans un cairn, marquer comme lu ou non lu, ouvrir dans le navigateur, et supprimer quand tous les articles sélectionnés n'ont plus d'abonnement. Sans article sélectionné, ces actions MUST être inactives.

#### Scenario: Trois articles cochés
- **WHEN** l'utilisateur coche trois articles en mode sélection
- **THEN** le titre de la liste devient « 3 sélectionnés » et les actions apparaissent sous la liste

#### Scenario: Aucune sélection
- **WHEN** l'utilisateur active le mode sélection sans cocher d'article
- **THEN** le titre affiche « Aucune sélection » et les actions sous la liste sont inactives
