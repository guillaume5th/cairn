# Proposal

## Why

Cairn n'existe que sur Mac : impossible de faire sa veille sur iPhone ou iPad. Tout le cœur (`CairnCore` : modèles SwiftData, flux, OPML, résumés) est déjà en Swift multiplateforme, à part le décodage d'images ; l'interface est en SwiftUI avec `NavigationSplitView`. Une version iOS coûte surtout des ajustements, pas une réécriture.

## What Changes

- Nouvelle cible d'application iOS universelle (iPhone et iPad), construite depuis les mêmes sources `App/` et le même package `CairnCore` que l'app Mac.
- L'app iOS est **autonome** : sa bibliothèque (abonnements, articles, cairns, tags, résumés) reste sur l'appareil. Pas de synchronisation avec le Mac ; on passe ses abonnements d'un appareil à l'autre par export/import OPML.
- Installation par Xcode sur ses propres appareils (signature automatique avec son équipe Apple). Pas de TestFlight, pas d'App Store, pas de changement au script de release Mac.
- Mise en page adaptée : trois colonnes sur iPad, navigation empilée sur iPhone (comportement standard de `NavigationSplitView`).
- Les commandes aujourd'hui réservées à la barre des menus Mac (importer/exporter OPML, Réglages, taille du texte, icônes dans la liste) deviennent accessibles depuis l'interface sur iOS. Sur iPad avec clavier, les raccourcis existants (⌘N, ⌘R, ⌘F, ⌘+, ⌘−, ⌘0) restent valables.
- Les réglages (heure du résumé, moteur, Ollama, conservation) s'ouvrent dans une feuille au lieu d'une fenêtre Réglages.
- Le résumé quotidien est produit quand l'app est au premier plan (au lancement ou au retour dans l'app si l'heure est passée) : iOS ne laisse pas tourner l'app en arrière-plan.
- Ollama reste utilisable via un serveur sur le réseau local (autorisation « réseau local » et HTTP non chiffré vers le réseau local).
- L'app Mac adopte le même mode sélection que l'iPhone et le même bouton « + » dans la barre latérale ; le reste de son comportement ne change pas.

## Capabilities

### New Capabilities
- `ios-app`: ce qui diffère sur iPhone et iPad — installation, données propres à l'appareil, mise en page, accès aux commandes sans barre des menus, réglages, cycle de vie et résumé quotidien au premier plan, accès au serveur Ollama du réseau local.

### Modified Capabilities
- `article-reading`: un mode sélection explicite (bouton « Sélectionner », cases, titre « N sélectionnés », actions sous la liste), commun au Mac et à l'iPhone ; le volet de lecture d'une sélection n'a plus d'actions sur Mac.

## Impact

- `project.yml` : nouvelle cible iOS (déploiement iOS 27, iPhone + iPad, signature automatique, Info.plist réseau local).
- `CairnCore/Package.swift` : plateforme iOS ajoutée. `FeedIcon.swift` : décodage d'image sans AppKit.
- `App/` : code AppKit isolé derrière `#if os(macOS)` ou remplacé par des API communes (`CairnApp`, `HTMLView`, `SourceIcon`, `SidebarView`) ; ajout d'un menu d'actions et d'une feuille Réglages pour iOS.
- `README.md` : instructions pour construire et installer sur iPhone/iPad.
- Aucune nouvelle dépendance. Aucun changement de modèle de données.
