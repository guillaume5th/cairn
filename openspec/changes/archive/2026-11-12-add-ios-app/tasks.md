# Tasks

## 1. CairnCore multiplateforme

- [x] 1.1 Ajouter `.iOS(.v27)` aux `platforms` de `CairnCore/Package.swift` ; vérifier que `swift build` passe toujours sur Mac
- [x] 1.2 Dans `FeedIcon.swift`, remplacer `NSImage` par ImageIO (`CGImageSource`) pour valider l'icône téléchargée, et faire prendre un `CGImage` à `isVisible` ; retirer `import AppKit`. Vérifier que `swift test` passe (les tests `FeedIconTests`, dont l'icône fantôme et l'icône trop grosse, restent verts ; les tests peuvent garder AppKit, ils tournent sur Mac)
- [x] 1.3 Dans `Summarizer.swift`, remplacer « Ce Mac » par « Cet appareil » et « Réglages Système » par « Réglages » dans `AppleSummarizer.message(for:)` ; vérifier `swift test` et `grep -rn "Ce Mac" CairnCore/Sources` vide
- [x] 1.4 Vérifier que le package compile pour iOS : `xcodebuild -scheme CairnCore -destination 'generic/platform=iOS Simulator' build` réussit

## 2. Cible iOS

- [x] 2.1 Ajouter dans `project.yml` la cible `Cairn iOS` (`platform: iOS`, `deploymentTarget` iOS 27.0, `TARGETED_DEVICE_FAMILY: "1,2"`, `sources: [App]`, dépendance `CairnCore`, `PRODUCT_BUNDLE_IDENTIFIER: dev.cairn.Cairn-$(DEVELOPMENT_TEAM)`, `CODE_SIGN_STYLE: Automatic`, `DEVELOPMENT_TEAM` via `Config/Signing.xcconfig` → `Config/Local.xcconfig` non versionné, `GENERATE_INFOPLIST_FILE`, icône `AppIcon`, `INFOPLIST_KEY_UILaunchScreen_Generation: YES`, orientations iPhone/iPad) ; vérifier que `xcodegen` génère un projet avec les schémas `Cairn` et `Cairn iOS`
- [x] 2.2 Ajouter à la cible iOS `NSLocalNetworkUsageDescription` (texte français : accès au serveur Ollama du réseau local) et `NSAppTransportSecurity > NSAllowsLocalNetworking = YES` via `info.properties` ; vérifier leur présence dans l'Info.plist du produit construit

## 3. Code d'app partagé Mac/iOS

- [x] 3.1 `CairnApp.swift` : garder sous `#if os(macOS)` le délégué, la scène `Window`, la scène `Settings` et l'observation de `willTerminate` ; sous iOS, `WindowGroup` avec le même contenu, `.commands { CairnCommands(state:) }`, et `state.save()` quand `scenePhase` passe à `.background`. Mettre `AppDelegate` sous `#if os(macOS)`
- [x] 3.2 `HTMLView.swift` : `LinkOpener` ouvre le lien avec `NSWorkspace` sur Mac et `UIApplication.shared.open` sur iOS ; `import AppKit` sous `#if os(macOS)`
- [x] 3.3 `SourceIcon.swift` : `DecodedIcon` décode via ImageIO en `CGImage` et la vue affiche `Image(decorative:scale:)` sur les deux plateformes ; `articleRowSide` garde `NSLayoutManager` sous `#if os(macOS)` et utilise `UIFont.preferredFont(forTextStyle:).lineHeight` sur iOS. Vérifier sur Mac que les icônes rondes / découpées s'affichent comme avant
- [x] 3.4 `SidebarView.swift` : `ActionMenu`/`NSMenu` sous `#if os(macOS)` ; sur iOS, le bouton « + » devient un `Menu` SwiftUI (« Ajouter un abonnement… », « Nouveau dossier… ») et un menu « … » dans la barre d'outils de la barre latérale porte « Importer OPML… », « Exporter OPML… », « Réglages… »
- [x] 3.5 Ajouter `isShowingSettings` à `AppState` et, sous `#if os(iOS)`, présenter depuis `ContentView` une feuille `NavigationStack { SettingsView() }` avec un bouton « OK »
- [x] 3.6 `SettingsView` : sous `#if os(iOS)`, ajouter une section « Affichage » avec la taille du texte (boutons −/+ et « Taille normale » via `TextScale.stepped`, bornes `TextScale.range`) et la case « Icônes dans la liste d'articles » (`showListIcons`)
- [x] 3.7 Ajouter `.refreshable { await state.refresh() }` à la liste d'articles et, sous `#if os(iOS)`, un `EditButton` dans sa barre d'outils pour la sélection multiple
- [x] 3.8 Vérifier que les deux cibles compilent : `xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build` et `xcodebuild -scheme 'Cairn iOS' -destination 'generic/platform=iOS Simulator' -derivedDataPath build build` réussissent sans avertissement nouveau
- [x] 3.9 Mettre à jour le README : prérequis iOS, commande de build simulateur, installation sur appareil (`Config/Local.xcconfig` puis `xcodegen`, choix de l'appareil dans Xcode, profil gratuit de 7 jours), données propres à l'appareil et transfert par OPML, limite ATS des flux `http://` publics, Ollama sur le réseau local (`OLLAMA_HOST=0.0.0.0`) ; vérifier que les commandes du README s'exécutent telles quelles

## 3bis. Ajustements après essais sur iPhone

- [x] 3.10 Ajout d'abonnement sur iOS dans la même alerte que « Nouveau dossier » (champ d'URL, Annuler/Ajouter, erreur dans l'alerte de message) ; logique d'ajout partagée avec la feuille Mac ; vérifier sur iPhone
- [x] 3.11 Bouton « + » de la barre latérale dans la barre d'outils, sur iOS et sur Mac (abonnement, dossier, cairn) ; vérifier que les en-têtes « Cairns » et « Abonnements » n'ont plus de bouton
- [x] 3.12 Mode sélection commun Mac/iPhone : bouton « Sélectionner », cases, titre « N sélectionnés », actions sous la liste, sortie qui vide la sélection (Échap sur Mac) ; vérifier sur les deux plateformes
- [x] 3.13 Barre d'un article dans l'ordre Résumer · Garder · Non lu · Safari, icône « non lu » à point central, retour à la liste après « non lu » sur iPhone
- [x] 3.14 Déclarer le type OPML (`org.opml.opml`, extension `.opml`, conforme à XML) dans l'Info.plist des apps Mac et iOS : sans déclaration, le sélecteur de fichiers de l'iPad grisait le fichier ; vérifier l'import sur iPad

## 4. Vérification sur simulateurs

- [x] 4.1 Simulateur iPhone : ajouter un abonnement, toucher un article (plein écran, marqué lu, retour à la liste), tirer pour rafraîchir, rechercher, garder dans un cairn, ouvrir un lien (Safari), importer et exporter un OPML via le menu « + », changer la taille du texte dans les Réglages. Vérifier aussi qu'au lancement l'app n'ouvre pas directement un article mémorisé ; sinon, ne pas restaurer la sélection d'article en largeur compacte
- [x] 4.2 Simulateur iPad : trois colonnes en paysage, sélection multiple via « Modifier », menu contextuel par appui long, raccourcis ⌘N/⌘R/⌘F/⌘+ avec le clavier du Mac
- [x] 4.3 Cycle de vie et résumé : garder un article, passer l'app en arrière-plan, la terminer depuis le sélecteur d'apps, relancer → l'article est gardé. Régler l'heure du résumé juste avant maintenant, mettre l'app en arrière-plan, revenir après l'heure → le résumé du jour est produit (Ollama sur le Mac hôte : `http://localhost:11434` fonctionne depuis le simulateur)
- [x] 4.4 App Mac : lancer et vérifier que rien n'a changé (fenêtre unique, menus Fichier/Présentation, Réglages ⌘,, fermer la fenêtre garde l'app dans le Dock, icônes des sources)

Vérifié sans interaction (iPhone 18 Pro et iPad Pro 11" sous iOS 27.2, avec une copie de la base Mac) : lancement, liste avec icônes des sources, article HTML sur iPad, mode sombre. L'iPhone ouvrait directement l'article mémorisé au lancement : corrigé dans `ContentView` (en largeur compacte, seul l'article ou le résumé touché par l'utilisateur est sélectionné).

## Workflow follow-up

- Installer sur un vrai iPhone/iPad depuis Xcode et tester Ollama via l'IP du Mac sur le réseau local (autorisation « réseau local »).
- Archiver le change une fois validé (`/opsx:archive`).
