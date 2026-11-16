# Proposal

## Why

Les résumés quotidiens s'accumulent dans leur liste sans qu'on sache lesquels on a déjà lus : il faut se souvenir des dates. Un état lu / non lu, comme pour les articles, montre d'un coup d'œil qu'un nouveau résumé attend.

## What Changes

- Un résumé qui vient d'être produit est non lu ; il devient lu dès qu'il est affiché seul dans le volet de lecture (clic dans la liste, notification, ou ouverture de l'entrée qui l'affiche).
- La liste des résumés montre une pastille devant chaque résumé non lu, la même que pour les articles.
- « Marquer comme lu / non lu » dans le menu contextuel de la liste (un ou plusieurs résumés) et en balayant une ligne vers la droite, comme pour les articles.
- L'entrée « Résumés quotidiens » de la barre latérale affiche le nombre de résumés non lus.
- Les résumés qui existent déjà avant la mise à jour sont considérés comme lus.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `daily-digest` : état lu / non lu des résumés quotidiens.

## Impact

- `CairnCore/Sources/CairnCore/Models.swift` : `Digest.isRead`.
- `App/DigestViews.swift` : pastille, menu contextuel, balayage, marquage à l'affichage.
- `App/SidebarView.swift` : compteur de l'entrée « Résumés quotidiens ».
- Pas de changement de la sauvegarde (elle ne contient pas les résumés) ni du badge du Dock (il compte les articles).
