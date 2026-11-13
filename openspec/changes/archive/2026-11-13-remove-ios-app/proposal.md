# Proposal

## Why

Cairn se concentre sur l'app Mac. L'app iPhone/iPad demande un compte Apple Developer payant pour être utilisable au quotidien (avec un Apple ID gratuit, l'app installée expire au bout de 7 jours), et chaque fonction doit aujourd'hui être pensée, codée et vérifiée pour deux plateformes. Retirer iOS allège le code et la maintenance.

## What Changes

- **BREAKING** Suppression de l'app iPhone/iPad : la cible Xcode `Cairn iOS` disparaît de `project.yml`, avec `iOS/Info.plist` et la configuration de signature iOS (`Config/Signing.xcconfig`, l'entrée `Config/Local.xcconfig` du `.gitignore`).
- Suppression du code propre à iOS dans `App/` : branches `#if os(iOS)` / `#else` (UIKit, `horizontalSizeClass`, navigation empilée, popover de partage iPad, tirer pour rafraîchir, cycle de vie `scenePhase`), et `App/BackgroundRefresh.swift` (tâches d'arrière-plan iOS). Les gardes `#if os(macOS)` deviennent inutiles et sont retirées : le code Mac reste tel quel.
- Les fonctions livrées depuis (partage, découverte de flux, article complet, résumé quotidien en arrière-plan quand la fenêtre est fermée) restent inchangées sur Mac.
- README : retrait des prérequis, commandes, instructions d'installation et remarques iPhone/iPad.
- Specs : retrait de la capacité `ios-app` ; `article-reading` ne mentionne plus l'iPhone ni l'iPad.

Hors périmètre : réécrire l'historique (`CHANGELOG.md`, changements archivés), toute évolution fonctionnelle de l'app Mac.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `ios-app`: toutes ses exigences sont retirées (plus d'app iPhone/iPad).
- `article-reading`: l'exigence « Titre et actions d'une sélection » ne vise plus que le Mac.

## Impact

- `project.yml` (cible `Cairn iOS`), `iOS/`, `Config/`, `.gitignore`.
- `App/` : `AppState`, `ArticleDetailView`, `BackgroundRefresh` (supprimé), `CairnApp`, `ContentView`, `DigestNotifications`, `DigestViews`, `HTMLView`, `SidebarView`, `SourceIcon`.
- `README.md`, `openspec/specs/ios-app`, `openspec/specs/article-reading`.
- Aucun impact sur `CairnCore`, ni sur les données ou l'identifiant `dev.cairn.Cairn` de l'app Mac.
