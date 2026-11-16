# Tasks

## 1. Modèle

- [x] 1.1 Ajouter `Digest.isRead`, déclaré à `true` (valeur reprise par la migration SwiftData pour les résumés existants) et mis à `false` dans `init`; vérifier par un test dans `DigestTests` qu'un `Digest` neuf est non lu, et `swift test` dans CairnCore

## 2. Interface

- [x] 2.1 Marquer lu le résumé affiché seul dans `DigestView` (`.task(id:)` sur le résumé, comme `ArticleDetailView`); vérifier dans Cairn Dev qu'un clic, l'ouverture de l'entrée et la notification le marquent lu, et qu'une sélection multiple ne le fait pas
- [x] 2.2 Pastille des non lus dans les lignes de `DigestListView`, en partageant `UnreadDot` de `ContentView.swift` (le rendre non privé); vérifier à l'écran l'alignement des lignes lues et non lues
- [x] 2.3 « Marquer comme lu / non lu » dans le menu contextuel de la liste (lot entier, même logique `anyUnread` que les articles) et en balayage vers la droite; vérifier dans Cairn Dev les deux sens, sur un et plusieurs résumés
- [x] 2.4 Compteur sur l'entrée « Résumés quotidiens » de `SidebarView` via une `@Query` des résumés non lus; vérifier qu'il passe à 1 après « Générer un résumé » et disparaît une fois le résumé affiché

- [x] 2.5 Corbeille en balayant une ligne vers la gauche, avec la confirmation existante (`digestsToDelete`); vérifier dans Cairn Dev que le résumé balayé, sélectionné ou non, est supprimé après confirmation

- [x] 2.6 Boutons « Sélectionner », « Non lus seulement » et « Tout marquer comme lu » dans la barre d'outils de la liste des résumés, comme celle des articles (`SelectionMark`, `TickOnClick` partagés); le résumé affiché par défaut est mémorisé pour que le filtre le garde listé; vérifier dans Cairn Dev le filtre, le mode sélection et Échap
- [x] 2.7 Bouton « Marquer comme lu / non lu » dans la barre d'outils du volet de lecture des résumés, pour le résumé affiché ou la sélection; vérifier dans Cairn Dev qu'un résumé remis en non lu garde sa pastille en restant affiché

## 3. Vérification

- [x] 3.1 Lancer `cairn-check` (tests CairnCore + build Xcode) et vérifier qu'il passe
- [x] 3.2 Vérifier avec `cairn-run`, sur les données de Cairn Dev, que les résumés existants restent lus après migration

## Workflow follow-up

- Archiver le change après revue, puis cocher l'idée dans le backlog (#20) si elle y figure.
