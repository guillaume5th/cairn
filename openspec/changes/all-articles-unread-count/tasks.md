# Tasks

## 1. Compteur de « Tous les articles »

- [x] 1.1 Dans `App/SidebarView.swift`, ajouter une `@Query` des articles non lus (`#Predicate { !$0.isRead }`) et `.badge(...count)` sur le label « Tous les articles », comme `.badge(feed.unreadCount)` pour les abonnements (un badge à 0 ne s'affiche pas) ; vérifier que `xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build` réussit
- [x] 1.2 Vérifier dans l'app : le nombre affiché est égal au nombre d'articles `ZISREAD = 0` en base ; choisir au clavier un article non lu le fait baisser de 1 ; activer le filtre « Non lus » ne le change pas ; un article gardé non lu sans abonnement est compté (ou, à défaut d'en avoir un, vérifier que la requête ne filtre pas sur l'abonnement)
