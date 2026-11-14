# Tasks

## 1. CairnCore

- [x] 1.1 `Article.readLaterAt: Date?` et `isQueued` dans `Models.swift` ; `Library.readLater(_:now:)` (pose la date, remet en non lu) et `Library.removeFromReadLater(_:)` ; tests dans `LibraryTests` : ajout d'un article lu le remet non lu, lecture le sort de la file, remise en non lu l'y ramène
- [x] 1.2 Purge : épargner les articles non lus de la file ; test dans `LibraryTests` (vieil article en file conservé, vieil article lu de la file purgé)
- [x] 1.3 `Backup.ArticleEntry.readLaterAt` optionnel, écrit et restauré ; étendre `BackupTests.roundTrip` et vérifier qu'une sauvegarde sans le champ se décode

## 2. App

- [x] 2.1 `SidebarItem.readLater` : titre, liste (`isQueued` ou sélectionné, tri par `readLaterAt` décroissant) dans `ContentView.swift` ; entrée « Lire plus tard » avec compteur sous « Aujourd'hui » dans `SidebarView.swift`
- [x] 2.2 `ReadLaterButton` dans `ArticleMenuItems` (après Garder, ⇧⌘D) et dans la barre d'outils du volet de lecture ; bascule sur la sélection
- [x] 2.3 Vérifier dans Cairn Dev (`/cairn-run`) : ajout par ⇧⌘D, compteur, lecture qui laisse la ligne jusqu'au changement de sélection, sortie de la file, article gardé + en file

## 3. Intégration

- [x] 3.1 `/cairn-check` : `swift test` vert et `BUILD SUCCEEDED`
