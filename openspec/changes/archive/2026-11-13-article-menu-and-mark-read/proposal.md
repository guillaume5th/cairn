# Proposal

## Why

Un audit des menus a relevé trois manques par rapport aux lecteurs RSS et à Mail : on ne peut pas marquer un abonnement ou un dossier comme lu sans l'ouvrir, copier le lien d'un article oblige à passer par la feuille de partage, et les actions sur un article n'ont aucun raccourci clavier faute de menu dans la barre des menus.

## What Changes

- Le menu contextuel d'un abonnement (ou de plusieurs) et celui d'un dossier proposent « Marquer tout comme lu », grisé quand il n'y a rien de non lu.
- Le menu contextuel d'un article propose « Copier le lien » (« Copier les liens » pour plusieurs articles, un par ligne).
- Un menu « Article » dans la barre des menus reprend les actions du menu contextuel d'un article, sur l'article affiché ou la sélection, avec des raccourcis : Garder ⇧⌘L, Marquer comme lu / non lu ⇧⌘U (comme Mail), Ouvrir dans le navigateur ⌘↩. Sans liste d'articles affichée, ses actions sont grisées.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : marquer un abonnement ou un dossier comme lu depuis la barre latérale ; menu « Article » et ses raccourcis.
- `sharing` : copier le lien d'un ou plusieurs articles.

## Impact

- `App/SidebarView.swift` : « Marquer tout comme lu » dans les menus d'un abonnement et d'un dossier.
- `App/ArticleDetailView.swift` : `ArticleMenuItems` gagne « Copier le lien » et des raccourcis, et sert aussi au menu « Article » (`ArticleCommands`, `ArticleSelection`).
- `App/ContentView.swift` : la liste d'articles publie sa sélection pour le menu.
- `App/CairnApp.swift` : le menu « Article ».
- Aucun impact sur `CairnCore` ni les données.
