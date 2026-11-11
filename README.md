# Cairn

A tech watch app.

Gather your sources, skim what's new, and keep the stones worth remembering,
one cairn at a time.

## Prérequis

- macOS 27 ou plus récent (Xcode 27)
- Xcode (premier lancement effectué : `sudo xcodebuild -runFirstLaunch`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) : `brew install xcodegen`

## Structure

- `CairnCore/` : package Swift avec toute la logique (modèles SwiftData, lecture des flux, OPML, rétention, recherche) et ses tests.
- `App/` : l'application SwiftUI macOS (vues et commandes uniquement).
- `project.yml` : description du projet Xcode. `Cairn.xcodeproj` est généré et n'est pas versionné.

## Commandes

```sh
# Tests de la logique
cd CairnCore && swift test && cd ..

# Générer le projet Xcode puis construire l'app
xcodegen
xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build

# Lancer l'app
open build/Build/Products/Debug/Cairn.app
```

Pour développer dans Xcode : `xcodegen && open Cairn.xcodeproj`.

Les données sont stockées localement dans
`~/Library/Containers/dev.cairn.Cairn/Data/Library/Application Support/default.store`.

## Dépendances

Dependabot (`.github/dependabot.yml`) vérifie chaque semaine les paquets Swift de `CairnCore` et ouvre une pull request à chaque nouvelle version. Avant de fusionner : `cd CairnCore && swift test`, puis construire l'app.
