# Tasks

## 1. Modèle et bibliothèque

- [x] 1.1 Ajouter `Folder` (`name`, `key`, `feeds`, relation nullify inverse de `Feed.folder`) dans `CairnCore/Sources/CairnCore/Models.swift` et l'inscrire dans `CairnStore.container` ; ajouter dans `Library` `createFolder(named:)`, `rename(_:to:)`, `move(_:to:)`, `delete(_ folder:)` (nom vide ou doublon par clé → erreur `CairnError.duplicateFolder`/rejet) ; tests : création, doublon « swift »/« Swift », renommage, déplacement, suppression qui garde les abonnements à la racine ; `swift test` passe

## 2. OPML avec dossiers

- [x] 2.1 `OPMLFeed.folder` ; `OPML.parse` attribue à chaque flux son dossier de premier niveau, `OPML.export` regroupe les flux par dossier ; `Library.importOPML` crée/réutilise les dossiers par clé pour les seuls flux ajoutés, `exportOPML` transmet le dossier ; adapter `parseFlattensFolders` (Deep → « Swift », top level sans dossier), ajouter : dossier existant réutilisé, réimport sans changement de dossier, export puis réimport dans une base vide recrée les mêmes dossiers ; `swift test` passe

## 3. Barre latérale

- [x] 3.1 Dans `App/SidebarView.swift` : dossiers repliables (état replié conservé sur ce Mac) avec icône, total de non lus et menu contextuel « Renommer… » / « Supprimer le dossier », abonnements sans dossier à la racine ; « + » devient un menu « Ajouter un abonnement… » / « Nouveau dossier… » avec saisie du nom ; menu contextuel d'abonnement « Déplacer vers » (dossiers + « Aucun dossier ») ; glisser un abonnement sur un dossier ou sur l'en-tête de section ; vérifier que le build réussit

## 4. Vue d'un dossier

- [x] 4.1 Dans `App/ContentView.swift` : `SidebarItem.folder`, articles des abonnements du dossier, titre = nom du dossier, canonicalisation de l'identifiant au lancement et retour à « Tous les articles » si le dossier n'existe plus ou est supprimé pendant qu'il est affiché ; vérifier que le build réussit

## 5. Vérification

- [x] 5.1 Vérifier dans l'app par captures et base sqlite : la base existante s'ouvre avec tous ses abonnements et articles ; créer, renommer, supprimer un dossier (abonnements conservés) ; doublon refusé ; ranger par glisser-déposer et par « Déplacer vers » ; compteur du dossier = somme ; repli conservé après relancement ; vue dossier avec recherche, filtre et sélection mémorisée ; import d'un OPML à dossiers et export qui les contient
