# Tasks

## 1. Modèle et lecture du flux

- [x] 1.1 Ajouter `Feed.iconData` et `Article.sourceIconData` (`@Attribute(.externalStorage)`, optionnels) et `Feed.iconCheckedAt: Date?` ; vérifier que `swift test` passe toujours, en particulier `storeRoundTrip` sur une base en mémoire
- [x] 1.2 Étendre `ParsedFeed` avec `siteURL` et `iconURL` remplis par `FeedParser` (RSS/RDF `channel.link` ; Atom `icon` et lien `alternate` du flux ; JSON Feed `favicon` puis `icon`, et `home_page_url`) ; ajouter `<icon>` à `atom.xml`, `favicon` et `home_page_url` à `feed.json`, et vérifier par des tests de `FeedParserTests` les valeurs lues pour les trois formats, y compris RSS sans icône

## 2. Recherche de l'icône

- [x] 2.1 Implémenter l'extraction des `<link rel=…icon…>` d'une page HTML (expression régulière bornée à `</head>`, `href` résolu par rapport à l'URL de la page, commentaire `shortcut:` du design) ; vérifier par des tests unitaires : `rel="icon"`, `rel="shortcut icon"`, attributs dans un autre ordre, majuscules, `href` relatif et absolu, page sans icône
- [x] 2.2 Implémenter dans `FeedFetcher` la recherche d'icône (icône déclarée par le flux, puis page d'accueil lue sur 256 Ko maximum, puis `/favicon.ico` ; candidat retenu seulement s'il fait au plus 512 Ko et se décode avec `NSImage(data:)`) ; ajouter au `StubProtocol` des hôtes servant une page avec `<link rel="icon">`, un `/favicon.ico` seul, une icône illisible et une icône trop grosse, et vérifier par un test chaque branche de l'ordre de recherche et le cas « aucune icône »
- [x] 2.3 Implémenter `Library.refreshIcons(context:fetcher:now:)` (abonnements jamais vérifiés ou vérifiés il y a plus de 7 jours, 6 en parallèle, `iconData` remplacé seulement par une icône trouvée, `iconCheckedAt` toujours mis à jour) ; vérifier par des tests : une icône est enregistrée, une seconde exécution le même jour ne lance aucune requête, un échec conserve l'icône existante, un abonnement vérifié il y a 8 jours est revérifié
- [x] 2.4 Classer les icônes déclarées par la page (`apple-touch-icon`, puis `sizes` décroissant), essayer `/apple-touch-icon.png` avant `/favicon.ico`, préférer JSON Feed `icon` à `favicon`, et rejeter une icône sans pixel au moins à moitié opaque ; vérifier par des tests l'ordre de préférence, le repli sur `/apple-touch-icon.png` et le rejet d'une icône quasi transparente

## 3. Articles gardés orphelins

- [x] 3.1 Dans `Library.delete(_ feed:)`, copier `feed.iconData` dans `sourceIconData` de chaque article gardé avant la suppression ; étendre `deletingFeedKeepsKeptArticles` pour vérifier que l'article gardé conserve l'icône après `save()`

## 4. Déclenchement dans l'app

- [x] 4.1 Appeler `Library.refreshIcons` à la fin de `AppState.refresh()` (après l'enregistrement des articles) et après l'ajout d'un abonnement dans `AddFeedSheet`, puis enregistrer ; vérifier à la main qu'un abonnement ajouté affiche son icône sans ⌘R, et qu'un ⌘R immédiat ne déclenche pas de nouvelle requête d'icône (aucun accès à la page d'accueil dans la console réseau ou par un point d'arrêt)

## 5. Affichage

- [x] 5.1 Créer la vue `SourceIcon` (données d'icône ou symbole générique `dot.radiowaves.up.forward`, à la taille d'un symbole dans le texte courant grâce à un symbole masqué, `scaledToFit`, cache en mémoire des images décodées) ; vérifier par un rendu `ImageRenderer` qu'une icône PNG, une icône ICO et des données absentes ou illisibles s'affichent à la même taille et alignées sur le texte
- [x] 5.2 Afficher `SourceIcon` devant le nom de l'abonnement dans `SidebarView`, devant `sourceTitle` dans la ligne de `ArticleListView` et dans l'en-tête de `ArticleDetailView`, en lisant `article.feed?.iconData ?? article.sourceIconData` ; vérifier à la main dans l'app, avec de vrais abonnements, les trois emplacements, l'icône générique d'un abonnement sans icône et l'icône d'un article gardé dont l'abonnement a été supprimé
- [x] 5.3 Présenter l'icône dans un cercle Liquid Glass partout, et dans la liste d'articles à gauche de la ligne, à un diamètre fixe égal à la hauteur d'une ligne au titre sur deux lignes ; vérifier dans l'app, en mesurant la capture, que tous les cercles de la liste ont le même diamètre et couvrent la hauteur d'une ligne de deux lignes
- [x] 5.4 Adapter l'icône au cercle avec une marge systématique : carrée pleine rognée en rond à 80 % du diamètre, logo détouré centré à 62 % ; vérifier dans l'app, après une nouvelle recherche des icônes, qu'aucune icône ne touche le bord de son cercle (Korben, OVH) et que les logos restent centrés

## 6. Vérification d'ensemble

- [x] 6.1 Lancer `swift test` dans `CairnCore/` et construire l'app avec les commandes du README ; vérifier que les deux passent, puis lancer l'app sur la base existante et vérifier que la migration s'applique sans perte (abonnements, articles gardés, notes et tags toujours présents) et que les icônes apparaissent après le premier rafraîchissement

## Workflow follow-up

- Archiver le change une fois validé (`/opsx:archive`).
