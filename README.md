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

## Installation

Télécharge le `.dmg` depuis les [Releases](https://github.com/guillaume5th/cairn/releases) et glisse Cairn dans Applications.
L'app n'est pas notarisée par Apple : au premier lancement, macOS la bloque. Débloque-la avec

```sh
xattr -dr com.apple.quarantine /Applications/Cairn.app
```

## Publier une version

Les commits suivent les [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `feat!:`).
À chaque push sur `main`, release-please ouvre ou met à jour une PR de release (version + `CHANGELOG.md`).
La merger crée le tag `vX.Y.Z` et la GitHub Release. Ensuite, en local :

```sh
git pull && git checkout vX.Y.Z && scripts/release.sh   # build Release, DMG, attaché à la release
```

## Résumé quotidien

Chaque jour à l'heure réglée (8 h par défaut), pendant que l'app est ouverte, Cairn rafraîchit les abonnements et fait résumer par une IA locale les articles publiés dans les 24 heures précédentes. Si l'app était fermée à cette heure-là, le résumé est fait au lancement suivant. Les résumés apparaissent dans l'entrée « Résumés » de la barre latérale et sont gardés 7 jours par défaut. « Présentation > Générer le résumé maintenant » relance à la main.

Réglages (⌘,) : heure, durée de conservation (1 à 90 jours) et moteur :

- **Apple** (par défaut) : le modèle intégré au Mac, qui demande Apple Intelligence activé.
- **Ollama** : un serveur local (`http://localhost:11434` par défaut). Le modèle se choisit dans la liste des modèles installés sur ce serveur ; installe-en un avec `ollama pull <modèle>`, puis actualise la liste.

Le modèle d'Apple lit environ 4 000 tokens : les jours chargés, seuls les premiers articles ont un extrait, les suivants n'apportent que leur titre.

## Dépendances

Dependabot (`.github/dependabot.yml`) vérifie chaque semaine les paquets Swift de `CairnCore` et ouvre une pull request à chaque nouvelle version. Avant de fusionner : `cd CairnCore && swift test`, puis construire l'app.
