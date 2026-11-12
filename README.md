<p align="center"><img src="docs/icon.png" width="128" alt="Icône de Cairn"></p>

# Cairn

A feed reader for your daily watch.

Gather your sources, skim what's new, and keep the stones worth remembering,
one cairn at a time.

## Prérequis

- macOS 27 ou plus récent (Xcode 27)
- Pour iPhone et iPad : iOS/iPadOS 27 et le simulateur iOS installé dans Xcode
- Xcode (premier lancement effectué : `sudo xcodebuild -runFirstLaunch`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) : `brew install xcodegen`

## Structure

- `CairnCore/` : package Swift avec toute la logique (modèles SwiftData, lecture des flux, OPML, rétention, recherche) et ses tests.
- `App/` : l'application SwiftUI (vues et commandes uniquement), partagée par la cible Mac `Cairn` et la cible iPhone/iPad `Cairn iOS`.
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

# Construire l'app iPhone/iPad pour le simulateur
xcodebuild -scheme 'Cairn iOS' -destination 'generic/platform=iOS Simulator' -derivedDataPath build build
```

Pour développer dans Xcode : `xcodegen && open Cairn.xcodeproj`.

Les données sont stockées localement dans
`~/Library/Containers/dev.cairn.Cairn/Data/Library/Application Support/default.store`.

## Installation

### iPhone et iPad

L'app iOS s'installe depuis Xcode, sur tes propres appareils :

```sh
echo 'DEVELOPMENT_TEAM = <ton identifiant d'équipe Apple>' > Config/Local.xcconfig   # une fois, non versionné
xcodegen && open Cairn.xcodeproj
```

Dans Xcode, choisis le schéma « Cairn iOS », ton iPhone ou iPad comme destination, puis Run.
L'identifiant d'équipe se trouve dans Xcode > Réglages > Comptes. L'identifiant de l'app est suffixé par cette équipe
(`dev.cairn.Cairn-<équipe>`), Apple refusant un identifiant déjà pris. Avec un Apple ID gratuit, l'app installée expire au bout de 7 jours :
relance-la depuis Xcode pour la réinstaller.

- Chaque appareil a sa propre bibliothèque, sans synchronisation. Pour retrouver tes abonnements, exporte-les en OPML sur le
  Mac (Fichier > Exporter OPML…) et importe le fichier sur l'iPhone (menu « … » de la barre latérale > Importer OPML…).
- iOS refuse les flux en `http://` non chiffré sur Internet : seuls les flux `https://` sont lisibles.
- Le résumé quotidien est produit quand l'app est à l'écran : iOS ne la laisse pas tourner en arrière-plan.
- Ollama : lance-le sur un Mac du réseau en écoute sur toutes les interfaces (`OLLAMA_HOST=0.0.0.0 ollama serve`), puis indique
  `http://<adresse du Mac>:11434` dans les Réglages de l'app et accepte l'accès au réseau local.

### Mac

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

## Abonnements

« Ajouter un abonnement » (⌘N) accepte l'adresse d'un flux ou simplement celle d'un site (`exemple.com` suffit) : Cairn
cherche les flux que la page déclare, puis les emplacements usuels (`/feed`, `/rss`, `/atom.xml`…). S'il en trouve plusieurs
(articles, commentaires, podcast…), il te laisse choisir. L'import et l'export OPML sont dans le menu Fichier (sur iOS,
dans le menu « … » de la barre latérale).

## Article complet

Quand un flux ne donne qu'un extrait, le bouton « Article complet » de la barre de l'article télécharge sa page et en garde
le texte principal (sans menus, publicités ni commentaires), avec l'extracteur du mode Lecture de Firefox
([Readability.js](https://github.com/mozilla/readability), Apache 2.0). Le texte est gardé avec l'article ; le même bouton
revient au contenu du flux. Dans le menu d'un abonnement, « Toujours charger l'article complet » le fait pour chaque nouvel
article. Le site de l'article est contacté comme par un navigateur, mais sans cookies, et aucun de ses scripts n'est exécuté.
Les résumés IA portent sur l'article complet quand il est chargé.

## Résumé quotidien

Chaque jour à l'heure réglée (8 h par défaut), pendant que l'app est ouverte, Cairn rafraîchit les abonnements et fait résumer par une IA locale les articles publiés dans les 24 heures précédentes. Si l'app était fermée à cette heure-là, le résumé est fait au lancement suivant. Les résumés apparaissent dans l'entrée « Résumés » de la barre latérale et sont gardés 7 jours par défaut. « Présentation > Générer le résumé maintenant » relance à la main.

Réglages (⌘,) : heure, durée de conservation (1 à 90 jours) et moteur :

- **Apple** (par défaut) : le modèle intégré au Mac, qui demande Apple Intelligence activé.
- **Ollama** : un serveur local (`http://localhost:11434` par défaut). Le modèle se choisit dans la liste des modèles installés sur ce serveur ; installe-en un avec `ollama pull <modèle>`, puis actualise la liste.

Le modèle d'Apple lit environ 4 000 tokens : les jours chargés, seuls les premiers articles ont un extrait, les suivants n'apportent que leur titre.

## Dépendances

Dependabot (`.github/dependabot.yml`) vérifie chaque semaine les paquets Swift de `CairnCore` et ouvre une pull request à chaque nouvelle version. Avant de fusionner : `cd CairnCore && swift test`, puis construire l'app.
