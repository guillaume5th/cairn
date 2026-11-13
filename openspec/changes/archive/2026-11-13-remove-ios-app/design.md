# Design

## Context

`App/` est partagé par deux cibles XcodeGen (`Cairn` macOS, `Cairn iOS`). Les différences passent par `#if os(iOS)` / `#if os(macOS)` dans 10 fichiers ; `BackgroundRefresh.swift` est entièrement iOS. `CairnCore` ne contient rien de propre à iOS. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Un seul target macOS, sans code conditionnel de plateforme dans `App/`.
- Comportement Mac strictement identique (build, données, identifiant d'app).

**Non-Goals:**
- Refactorer ou simplifier le code Mac au-delà de ce que le retrait d'iOS rend mort.
- Réécrire l'historique git, le `CHANGELOG.md` ou les changements archivés.

## Decisions

- **Suppression plutôt que `git revert`** : l'app iOS (#6) a été suivie de commits qui touchent le même code (#8, #11). Revenir en arrière défairait aussi des fonctions Mac. On retire le code iOS à la main, fichier par fichier.
- **Garder la branche macOS, retirer les gardes** : pour chaque `#if os(macOS) A #else B #endif`, on garde `A` sans directive ; pour `#if os(iOS) … #endif`, on supprime le bloc. Garder des gardes inutiles laisserait croire qu'une autre plateforme existe.
- **Code devenu mort** : ce qui n'existait que pour iOS est supprimé avec lui (`BackgroundRefresh`, `AppState.runInBackground`, le chemin `inBackground: true` de `makeDigest` s'il n'a plus d'appelant Mac, les wrappers de partage iPad, l'environnement `horizontalSizeClass`). Ce qui sert encore au Mac reste, même s'il avait été introduit avec iOS (ex. le formulaire d'ajout d'abonnement partagé, la section Affichage des Réglages).
- **`Config/`** : `Signing.xcconfig` ne sert qu'à la cible iOS ; il est supprimé avec l'entrée `.gitignore` de `Local.xcconfig`. Le fichier local `Config/Local.xcconfig` (non versionné, contient l'identifiant d'équipe) est signalé à l'utilisateur plutôt que supprimé d'office.
- **Spec `ios-app`** : toutes ses exigences passent en REMOVED ; après archivage, le dossier `openspec/specs/ios-app` vide est supprimé.

## Risks / Trade-offs

- [Une branche `#else` contenait en fait du code utile au Mac] → relire chaque bloc, puis build macOS et lancement de l'app.
- [Les tests `CairnCore` ne couvrent pas `App/`] → vérification manuelle : ajouter un abonnement, lire, partager, article complet, résumé, Réglages.
- [Le projet Xcode généré garde l'ancien schéma iOS] → `xcodegen` régénère `Cairn.xcodeproj` (non versionné).

## Migration Plan

Aucune migration de données. Les personnes ayant installé l'app iOS la gardent jusqu'à expiration ; leurs abonnements restent exportables en OPML depuis l'app tant qu'elle tourne. Retour arrière : `git revert` du commit de ce changement.
