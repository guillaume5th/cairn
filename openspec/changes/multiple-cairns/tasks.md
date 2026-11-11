# Tasks

## 1. Modèle et bibliothèque

- [x] 1.1 Ajouter `Cairn` et `Article.cairn` dans `Models.swift` (inscrit dans `CairnStore.container`) ; dans `Library` : `keep(_:in:)` (qui déplace aussi un article déjà gardé), `unkeep(_:)` qui vide `cairn`, `createCairn`, `rename`, `delete` (erreur `CairnError.lastCairn`), `ensureCairn`, vérification de nom partagée avec les dossiers ; tests : garder dans un cairn, déplacement qui garde note et tags, doublon refusé, dernier cairn non supprimable, suppression qui retire les articles (note et tags vidés), `ensureCairn` sur une base sans cairn avec articles gardés puis seconde exécution sans effet ; `swift test` passe

## 2. Lancement et listes

- [x] 2.1 Appeler `ensureCairn` dans `AppState.launch` avant la purge ; dans `ContentView` : `SidebarItem.cairn(id)` et `.tag(id, key)`, articles du cairn (et du tag dans ce cairn) triés par date de garde, titres, canonicalisation et retour à « Tous les articles » si l'entrée a disparu ; vérifier que le build réussit

## 3. Barre latérale

- [x] 3.1 Dans `SidebarView` : section « Cairns » avec « + » (« Nouveau cairn… »), chaque cairn suivi de ses tags en retrait, menu contextuel « Renommer… » / « Supprimer le cairn… » (désactivé pour le dernier, confirmation avec le nombre d'articles, retour à « Tous les articles » si le cairn affiché est supprimé) ; alerte de nom commune aux dossiers et aux cairns ; vérifier que le build réussit

## 4. Garder dans un cairn

- [x] 4.1 `KeepButton` : bouton bascule avec un seul cairn, sinon menu des cairns (actuel coché, choisir un autre cairn déplace) et « Retirer du cairn » ; même contenu sous « Garder dans » dans le menu contextuel des articles ; vérifier que le build réussit

## 5. Vérification

- [x] 5.1 Vérifier dans l'app par captures et base sqlite (base sauvegardée avant, restaurée après) : au premier lancement, les articles déjà gardés sont dans « Cairn » avec notes et tags ; avec un seul cairn, « Garder » agit directement ; créer « Pro », doublon refusé ; garder un article dans « Pro » via le bouton et via le clic droit ; déplacer un article annoté vers un autre cairn ; tags affichés sous le bon cairn et filtre par tag ; recherche dans un cairn ; renommer ; supprimer un cairn avec confirmation et nombre d'articles ; dernier cairn non supprimable
