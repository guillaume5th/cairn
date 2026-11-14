# feed-subscriptions Specification

## Purpose

Permet à l'utilisateur de choisir les sources de sa veille : s'abonner à des flux RSS/Atom, les gérer, et les échanger avec d'autres lecteurs via OPML.

## Requirements

### Requirement: Ajouter un abonnement par URL
Le système SHALL permettre d'ajouter un abonnement à partir de l'URL d'un flux RSS ou Atom, ou de l'adresse d'un site qui en déclare un. La saisie MUST se faire, sur tous les appareils, dans une alerte avec un champ URL, comme « Nouveau dossier ». Le système MUST vérifier que l'URL retenue renvoie un flux lisible avant d'enregistrer l'abonnement, et utiliser le titre du flux comme nom de l'abonnement.

#### Scenario: Flux valide
- **WHEN** l'utilisateur saisit l'URL d'un flux RSS ou Atom valide
- **THEN** l'abonnement est enregistré avec le titre du flux et ses articles apparaissent

#### Scenario: URL invalide ou injoignable
- **WHEN** l'utilisateur saisit une URL injoignable, ou une page qui n'est pas un flux et où aucun flux n'est trouvé
- **THEN** aucun abonnement n'est créé et un message d'erreur explique le problème

#### Scenario: Flux déjà suivi
- **WHEN** l'utilisateur saisit l'URL d'un flux auquel il est déjà abonné, ou celle d'un site dont le seul flux est déjà suivi
- **THEN** aucun doublon n'est créé et l'utilisateur en est informé

### Requirement: Lister les abonnements
Le système SHALL afficher la liste des abonnements avec, pour chacun, son nom et le nombre d'articles non lus.

#### Scenario: Affichage de la liste
- **WHEN** l'utilisateur ouvre l'application avec au moins un abonnement
- **THEN** chaque abonnement apparaît avec son nom et son nombre d'articles non lus

### Requirement: Supprimer un abonnement
Le système SHALL permettre de supprimer un abonnement. Ses articles non gardés MUST être supprimés ; ses articles gardés dans le cairn MUST être conservés.

#### Scenario: Suppression avec articles gardés
- **WHEN** l'utilisateur supprime un abonnement dont un article est gardé
- **THEN** l'abonnement et ses articles non gardés disparaissent, l'article gardé reste dans le cairn

### Requirement: Classer les abonnements dans des dossiers
Le système SHALL permettre de créer des dossiers nommés et d'y ranger les abonnements, sur un seul niveau. Un abonnement MUST être dans au plus un dossier ; les abonnements sans dossier restent à la racine. Deux dossiers MUST NOT porter le même nom (casse et accents ignorés). Chaque dossier MUST afficher le total des articles non lus de ses abonnements.

#### Scenario: Créer un dossier
- **WHEN** l'utilisateur choisit « Nouveau dossier… » et saisit « Swift »
- **THEN** un dossier « Swift » vide apparaît dans la section Abonnements

#### Scenario: Nom déjà pris
- **WHEN** l'utilisateur crée ou renomme un dossier avec le nom « swift » alors qu'un dossier « Swift » existe
- **THEN** aucun dossier n'est créé ni renommé et l'utilisateur en est informé

#### Scenario: Ranger par glisser-déposer
- **WHEN** l'utilisateur fait glisser un abonnement sur le dossier « Swift »
- **THEN** l'abonnement apparaît dans « Swift » et n'est plus à la racine ni dans son ancien dossier

#### Scenario: Ranger par le menu contextuel
- **WHEN** l'utilisateur choisit « Déplacer vers » > « Aucun dossier » sur un abonnement rangé
- **THEN** l'abonnement revient à la racine de la section Abonnements

#### Scenario: Compteur du dossier
- **WHEN** le dossier « Swift » contient deux abonnements avec 3 et 4 articles non lus
- **THEN** le dossier affiche 7

#### Scenario: Replier un dossier
- **WHEN** l'utilisateur replie le dossier « Swift »
- **THEN** ses abonnements sont masqués dans la barre latérale et son compteur reste visible

### Requirement: Renommer et supprimer un dossier
Le système SHALL permettre de renommer un dossier et de le supprimer. La suppression d'un dossier MUST conserver ses abonnements et leurs articles, qui reviennent à la racine.

#### Scenario: Renommer
- **WHEN** l'utilisateur renomme le dossier « Swift » en « Apple »
- **THEN** le dossier s'appelle « Apple » et garde ses abonnements

#### Scenario: Supprimer
- **WHEN** l'utilisateur supprime un dossier contenant deux abonnements
- **THEN** le dossier disparaît, les deux abonnements sont à la racine avec tous leurs articles

### Requirement: Importer un fichier OPML
Le système SHALL permettre d'importer un fichier OPML et de créer un abonnement pour chaque flux qu'il contient, y compris les flux imbriqués dans des dossiers. Chaque nouvel abonnement MUST être rangé dans le dossier de premier niveau qui le contient, créé s'il n'existe pas (même nom, casse et accents ignorés) ; les sous-dossiers sont fusionnés dans ce dossier. Les flux déjà suivis MUST être ignorés et garder leur dossier actuel.

#### Scenario: Import d'un OPML avec dossiers
- **WHEN** l'utilisateur importe un OPML contenant des flux répartis dans des dossiers
- **THEN** un abonnement est créé pour chaque flux, rangé dans un dossier du même nom que son dossier de premier niveau

#### Scenario: Sous-dossier
- **WHEN** l'OPML contient un flux dans le dossier « Inner », lui-même dans le dossier « Swift »
- **THEN** l'abonnement est rangé dans le dossier « Swift »

#### Scenario: Dossier existant
- **WHEN** l'OPML contient un dossier « swift » et qu'un dossier « Swift » existe déjà
- **THEN** les nouveaux abonnements sont rangés dans « Swift » et aucun dossier n'est ajouté

#### Scenario: Réimport du même fichier
- **WHEN** l'utilisateur importe un OPML dont tous les flux sont déjà suivis
- **THEN** aucun abonnement n'est ajouté, aucun abonnement ne change de dossier et l'utilisateur voit le nombre de flux ignorés

#### Scenario: Fichier OPML illisible
- **WHEN** l'utilisateur importe un fichier qui n'est pas un OPML valide
- **THEN** aucun abonnement n'est créé et un message d'erreur est affiché

### Requirement: Exporter les abonnements en OPML
Le système SHALL permettre d'exporter tous les abonnements dans un fichier OPML 2.0 que l'utilisateur enregistre où il le souhaite. Chaque flux MUST y figurer avec son nom et son URL, à l'intérieur de son dossier s'il en a un.

#### Scenario: Export puis réimport
- **WHEN** l'utilisateur exporte ses abonnements puis réimporte le fichier dans une base vide
- **THEN** les mêmes abonnements sont recréés, dans les mêmes dossiers

### Requirement: Sélectionner plusieurs abonnements
Le système SHALL permettre de sélectionner plusieurs abonnements dans la barre latérale (⌘-clic, ⇧-clic) et lister alors ensemble leurs articles, du plus récent au plus ancien, comme pour un dossier. Seuls des abonnements peuvent être sélectionnés ensemble : ajouter une autre entrée (« Tous les articles », dossier, cairn, tag, « Résumés quotidiens ») à la sélection MUST la remplacer par cette seule entrée.

#### Scenario: Deux abonnements sélectionnés
- **WHEN** l'utilisateur sélectionne un abonnement puis ⌘-clique sur un second
- **THEN** les articles des deux abonnements sont listés ensemble du plus récent au plus ancien, et aucun autre

#### Scenario: Ajout d'une entrée qui n'est pas un abonnement
- **GIVEN** deux abonnements sont sélectionnés
- **WHEN** l'utilisateur ⌘-clique sur un dossier
- **THEN** seul ce dossier est sélectionné

#### Scenario: Sélection multiple non mémorisée
- **GIVEN** deux abonnements sont sélectionnés
- **WHEN** l'utilisateur quitte puis relance l'app
- **THEN** la dernière entrée sélectionnée seule avant cette sélection est affichée

### Requirement: Déplacer plusieurs abonnements
Le système SHALL permettre de déplacer d'un coup les abonnements sélectionnés vers un dossier ou à la racine, par le menu contextuel « Déplacer vers » ou en faisant glisser la sélection sur un dossier.

#### Scenario: Déplacer par le menu
- **GIVEN** trois abonnements sont sélectionnés
- **WHEN** l'utilisateur choisit « Déplacer vers » puis le dossier « Cloud » dans le menu contextuel de l'un d'eux
- **THEN** les trois abonnements sont dans « Cloud »

#### Scenario: Déplacer en faisant glisser
- **GIVEN** deux abonnements sont sélectionnés
- **WHEN** l'utilisateur fait glisser l'un d'eux sur le dossier « Blogs »
- **THEN** les deux abonnements sont dans « Blogs »

### Requirement: Supprimer plusieurs abonnements
Le système SHALL permettre de supprimer d'un coup les abonnements sélectionnés après une seule confirmation, qui indique leur nombre. Chaque abonnement est supprimé comme un abonnement seul : ses articles non gardés sont supprimés, ses articles gardés conservés.

#### Scenario: Supprimer trois abonnements
- **GIVEN** trois abonnements sont sélectionnés
- **WHEN** l'utilisateur choisit « Supprimer 3 abonnements… » puis confirme
- **THEN** les trois abonnements et leurs articles non gardés sont supprimés, leurs articles gardés restent dans leur cairn, et « Tous les articles » est affiché

### Requirement: Découvrir le flux d'un site
Le système SHALL, quand l'adresse saisie renvoie une page web plutôt qu'un flux, chercher les flux RSS, Atom ou JSON Feed qu'elle déclare, puis, si elle n'en déclare aucun, essayer les emplacements usuels du site (`/feed`, `/rss`, `/rss.xml`, `/feed.xml`, `/atom.xml`, `/index.xml`). Un seul flux trouvé MUST être ajouté directement.

#### Scenario: Site qui déclare son flux
- **GIVEN** la page d'accueil de `https://exemple.com` déclare un flux Atom
- **WHEN** l'utilisateur saisit `https://exemple.com`
- **THEN** l'abonnement à ce flux est créé, avec le titre du flux

#### Scenario: Flux à un emplacement usuel
- **GIVEN** la page d'un site ne déclare aucun flux mais `https://exemple.com/feed` en est un
- **WHEN** l'utilisateur saisit l'adresse du site
- **THEN** l'abonnement à `https://exemple.com/feed` est créé

#### Scenario: Aucun flux trouvé
- **WHEN** l'utilisateur saisit l'adresse d'un site qui n'a aucun flux
- **THEN** aucun abonnement n'est créé et un message indique qu'aucun flux n'a été trouvé sur ce site

### Requirement: Choisir parmi plusieurs flux
Le système SHALL, quand une page déclare plusieurs flux, les proposer à l'utilisateur avec le titre et l'adresse de chacun, et n'ajouter que celui qu'il choisit. Les flux déjà suivis MUST être signalés comme tels et ne pas pouvoir être ajoutés de nouveau.

#### Scenario: Articles et commentaires
- **GIVEN** un site déclare un flux des articles et un flux des commentaires
- **WHEN** l'utilisateur saisit l'adresse du site
- **THEN** les deux flux sont proposés et seul celui qu'il choisit devient un abonnement

#### Scenario: Annuler le choix
- **WHEN** l'utilisateur annule le choix entre plusieurs flux
- **THEN** aucun abonnement n'est créé

### Requirement: Adresse sans schéma
Le système SHALL accepter une adresse saisie sans schéma (« exemple.com » ou « exemple.com/blog ») en la complétant par `https://`.

#### Scenario: Nom de domaine seul
- **WHEN** l'utilisateur saisit « exemple.com »
- **THEN** Cairn cherche le flux à `https://exemple.com`

### Requirement: Renommer un abonnement
Le système SHALL proposer « Renommer… » dans le menu contextuel d'un abonnement. Le nouveau titre MUST remplacer celui du flux dans la barre latérale, la liste d'articles et les articles déjà reçus, et MUST être conservé aux rafraîchissements suivants. Un titre vide MUST être refusé.

#### Scenario: Titre plus court
- **WHEN** l'utilisateur renomme « Simon Willison's Weblog » en « Simon »
- **THEN** la barre latérale et les lignes de ses articles affichent « Simon »

#### Scenario: Rafraîchissement
- **GIVEN** un abonnement renommé
- **WHEN** ses flux sont rafraîchis
- **THEN** il garde le titre choisi par l'utilisateur

#### Scenario: Titre vide
- **WHEN** l'utilisateur valide un titre vide
- **THEN** une erreur s'affiche et le titre ne change pas

### Requirement: S'abonner depuis un lien feed:
Le système SHALL ouvrir les liens `feed:`, sous la forme `feed:` suivi d'une adresse complète ou `feed://` suivi d'une adresse sans schéma, en affichant « Ajouter un abonnement » pré-rempli de l'adresse du flux. L'abonnement MUST n'être ajouté qu'après confirmation de l'utilisateur, comme une adresse saisie.

#### Scenario: Lien avec adresse complète
- **WHEN** l'utilisateur ouvre le lien `feed:https://exemple.com/rss`
- **THEN** Cairn passe au premier plan et propose d'ajouter `https://exemple.com/rss`

#### Scenario: Lien sans schéma
- **WHEN** l'utilisateur ouvre le lien `feed://exemple.com/rss`
- **THEN** Cairn propose d'ajouter `exemple.com/rss`, complété en https comme une adresse saisie
