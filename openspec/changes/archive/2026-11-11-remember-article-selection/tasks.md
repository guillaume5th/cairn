# Tasks

## 1. Mémoire de sélection persistée

- [x] 1.1 Rendre `SidebarItem` `Codable` et remplacer les `@State` `selection` / `selectedArticleID` de `ContentView` par une structure `Codable` (entrée courante + `[SidebarItem: PersistentIdentifier]`) stockée en JSON dans une clé `@AppStorage`, avec repli sur « Tous les articles » sans mémoire si la clé est absente ou illisible ; vérifier que `xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build` réussit sans avertissement de concurrence
- [x] 1.2 Calculer l'article affiché (article mémorisé de l'entrée s'il existe encore, sinon premier de `visibleArticles`), et au changement d'entrée comme au lancement remplacer dans la mémoire l'article absent de `visibleArticles` par le premier visible ; supprimer la remise à `nil` de `onChange(of: selection)` ; vérifier dans l'app : au lancement le premier article de « Tous les articles » est affiché, sélectionner le 3e, ouvrir « Cairn » puis un abonnement, revenir : le 3e est de nouveau sélectionné ; deux abonnements gardent chacun leur article
- [x] 1.3 Au lancement, remplacer par `.all` une entrée `.feed` absente des abonnements (`@Query` des abonnements) ou `.tag` absente des tags d'articles gardés ; vérifier dans l'app : quitter sur l'article A d'un abonnement, relancer, A est affiché ; quitter sur un abonnement, le supprimer depuis une autre session ou en éditant la clé (`defaults write`) vers un identifiant inconnu, relancer, « Tous les articles » est affiché

## 2. Lu seulement au choix de l'utilisateur

- [x] 2.1 Passer au `List` d'`ArticleListView` un binding dont le `set` écrit la mémoire et lève `marksRead`, les écritures programmatiques le baissant ; ajouter `marksRead` à `ArticleDetailView` et conditionner `article.isRead = true` dans sa `.task` ; vérifier dans l'app : ouvrir un abonnement avec des non lus, le premier est affiché et reste en gras avec un compteur inchangé ; cliquer le 2e ou y descendre au clavier le marque lu
- [x] 2.2 Vérifier dans l'app le scénario « Non lus » : filtre actif, revenir sur une entrée dont l'article mémorisé est lu, le premier non lu est affiché et reste non lu, aucun autre article ne change ; cliquer un article non lu, il est marqué lu et reste affiché

## 3. Intégration

- [x] 3.1 Lancer `swift test` dans `CairnCore/` et le build `xcodebuild` ; vérifier que les deux passent et que `openspec validate remember-article-selection --strict` ne signale rien
