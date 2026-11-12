# Design

## Context

- `CairnCore` (SwiftPM) déclare seulement `.macOS(.v27)`. Son seul code AppKit est dans `FeedIcon.swift` : `NSImage` sert à valider une icône téléchargée et à tester qu'elle est visible (`isVisible`). SwiftData, FoundationModels, URLSession et FeedKit existent tous sur iOS.
- `App/` est en SwiftUI. Le code propre au Mac est concentré dans :
  - `CairnApp.swift` : `@NSApplicationDelegateAdaptor`, scène `Window`, scène `Settings`, `NSApplication.willTerminateNotification`, `.commands`.
  - `HTMLView.swift` : `NSWorkspace.shared.open` dans le `NavigationDeciding` des liens.
  - `SourceIcon.swift` : `NSImage` (`DecodedIcon`), `Image(nsImage:)`, `NSLayoutManager` pour `articleRowSide`.
  - `SidebarView.swift` : `ActionMenu` qui ouvre un `NSMenu` sous la souris pour le bouton « + ».
- Les commandes import/export OPML, taille du texte et « Icônes dans la liste d'articles » n'existent que dans la barre des menus (`CairnCommands`).
- Les messages de `AppleSummarizer.message(for:)` disent « Ce Mac ».
- Le projet Xcode est généré par XcodeGen depuis `project.yml` (cible `Cairn`, macOS, signature ad hoc).

## Goals / Non-Goals

**Goals:**
- Une cible iOS qui compile depuis les mêmes fichiers `App/` et le même `CairnCore`, sans dupliquer de vue.
- L'app Mac reste identique (mêmes fichiers, même cible, même script de release).

**Non-Goals:**
- Synchronisation iCloud/CloudKit, TestFlight, App Store, CI iOS.
- Rafraîchissement ou résumé en arrière-plan (`BGTaskScheduler`), notifications.
- Refonte de l'interface pour iOS au-delà de ce que la spec `ios-app` exige (pas de widgets, pas de gestes de balayage).
- Adapter le texte des specs Mac existantes (⌘-clic, Dock…) : elles décrivent l'app Mac.

## Decisions

### Une seconde cible XcodeGen plutôt qu'une cible multiplateforme
Ajouter une cible `Cairn iOS` (`platform: iOS`, `deploymentTarget: 27.0`, `TARGETED_DEVICE_FAMILY: "1,2"`) avec `sources: [App]` et la même dépendance `CairnCore`.
- Pourquoi : la cible Mac garde sa signature ad hoc, son sandbox, son hardened runtime et `scripts/release.sh` sans aucun changement. La cible iOS a sa propre signature automatique.
- Alternative écartée : une seule cible avec `supportedDestinations: [macOS, iOS]`. Moins de YAML, mais mélange les réglages de signature (ad hoc Mac vs équipe Apple iOS) et touche la cible qui sert à la release.
- `Cairn.entitlements` n'est pas utilisé par la cible iOS (le sandbox est implicite sur iOS).

### Signature : équipe dans un xcconfig local non versionné
La cible iOS inclut `Config/Signing.xcconfig` (versionné), qui inclut de façon facultative `Config/Local.xcconfig` (ignoré par git) contenant `DEVELOPMENT_TEAM`. `CODE_SIGN_STYLE: Automatic`.
- Pourquoi : une variable d'environnement lue par XcodeGen se perdait dès qu'on régénérait le projet sans elle (Xcode ou un autre terminal) ; le fichier local survit à toutes les régénérations. Sans fichier, le projet se génère quand même ; seul le build sur appareil demande l'équipe. Le simulateur n'en a pas besoin.
- Bundle ID iOS : `dev.cairn.Cairn-$(DEVELOPMENT_TEAM)`. `dev.cairn.Cairn` est refusé par Apple (« not available ») pour une équipe gratuite ; le suffixe d'équipe le rend unique sans réglage à la main.

### Code propre à une plateforme : `#if os(macOS)` au plus près, API communes quand elles existent
- `FeedIcon` : remplacer `NSImage` par ImageIO (`CGImageSourceCreateWithData` + `CGImageSourceCreateImageAtIndex`), disponible sur les deux plateformes. `isVisible` prend un `CGImage`. Supprime `import AppKit` du package.
- `DecodedIcon` : stocker un `CGImage` (décodé via ImageIO comme ci-dessus) et afficher `Image(decorative:scale:)`. Une seule implémentation, plus de `NSImage`/`UIImage`.
- `SourceIcon.articleRowSide` : `#if os(macOS)` garde `NSLayoutManager` ; iOS utilise `UIFont.preferredFont(forTextStyle:).lineHeight`.
- `HTMLView.LinkOpener` : `#if os(macOS)` `NSWorkspace.shared.open`, sinon `UIApplication.shared.open` (le `NavigationDeciding` n'a pas accès à `openURL` de l'environnement).
- `SidebarView` bouton « + » : `#if os(macOS)` garde `ActionMenu`/`NSMenu` (choisi pour son rendu Mac) ; iOS utilise un `Menu` SwiftUI avec les mêmes deux actions. Un menu « … » dans la barre d'outils de la barre latérale porte « Importer OPML… », « Exporter OPML… » et « Réglages… » : les commandes que le Mac met dans ses menus (les ranger sous « + » mêlerait ajout et réglages).
- `CairnApp` : `#if os(macOS)` garde `Window`, `Settings`, le délégué et `willTerminate`. iOS : `WindowGroup` avec le même contenu, `.commands { CairnCommands }` (iPadOS affiche ces commandes et leurs raccourcis au clavier), et sauvegarde sur `scenePhase == .background`.
  - Alternative écartée : `WindowGroup` aussi sur Mac. Changerait le comportement Mac (plusieurs fenêtres, ⌘N).
- Réglages iOS : la feuille réutilise `SettingsView` dans une `NavigationStack` avec un bouton « OK », et lui ajoute sous `#if os(iOS)` une section « Affichage » (pas de taille du texte via `TextScale.stepped`, case « Icônes dans la liste d'articles »). Un booléen `isShowingSettings` dans `AppState`, comme `isAddingFeed`.
- Pull-to-refresh : `.refreshable { await state.refresh() }` sur la liste d'articles. Compile aussi sur Mac où il est sans effet visible ; pas besoin de `#if`.

### Résumé quotidien : aucun changement de logique
La boucle de `AppState.launch()` (vérifie `DigestSettings.isDue` chaque minute) tourne quand l'app est active et est suspendue avec elle en arrière-plan ; au retour au premier plan, le `Task.sleep` se termine et la vérification suivante rattrape le résumé. C'est exactement la règle « au lancement, au retour, ou à l'heure si l'app est ouverte ». `launched` empêche déjà de refaire le démarrage.

### Ollama sur le réseau local
Info.plist de la cible iOS : `NSLocalNetworkUsageDescription` (texte en français) et `NSAppTransportSecurity > NSAllowsLocalNetworking = YES` pour permettre `http://` vers des IP/hôtes `.local`. Pas d'`NSAllowsArbitraryLoads`. Les flux en `http://` public restent soumis à ATS : comportement différent du Mac — voir Risques.

### Messages d'Apple Intelligence neutres
Remplacer « Ce Mac » par « Cet appareil » dans `AppleSummarizer.message(for:)` et « Réglages Système » par « Réglages » : vrai sur les deux plateformes, pas de `#if` dans le package.

### Sélection multiple sur iOS
Les `List(selection: Set<…>)` existantes fonctionnent telles quelles : sur iOS un toucher sélectionne un seul élément et navigue ; la sélection multiple passe par le mode édition. On ajoute un `EditButton` dans la barre d'outils de la liste d'articles sous `#if os(iOS)`. Les menus contextuels (`contextMenu(forSelectionType:)`) s'ouvrent par appui long.

## Risks / Trade-offs

- [ATS bloque les flux en `http://` public sur iOS, alors que le Mac les lit] → Ajouter `NSAllowsArbitraryLoads` serait trop large ; on accepte la limite et on la note dans le README. À revoir si un abonnement réel est touché (l'erreur existante « flux illisible » s'affiche).
- [Apple ID gratuit : profil valable 7 jours, l'app cesse de s'ouvrir ensuite] → Documenté dans le README ; relancer depuis Xcode la réinstalle.
- [Divergence Mac/iOS dans les vues partagées : un changement Mac casse la build iOS sans qu'on le voie] → La tâche de vérification construit les deux cibles ; le README donne les deux commandes `xcodebuild`.
- [`WebView`/`WebPage` ou `glassEffect` se comportent différemment sur iOS] → Vérification manuelle sur simulateur iPhone et iPad (tâches finales).
- [Sur iPhone, `NavigationSplitView` replié et la restauration de sélection mémorisée (« remember-article-selection ») peuvent pousser directement un article au lancement] → Vérifier sur simulateur ; si c'est le cas, ne pas restaurer la sélection d'article en largeur compacte.

## Migration Plan

Aucune migration de données : nouvelle installation sur iOS, base vide. L'app Mac n'est pas touchée. Retour arrière : supprimer la cible iOS de `project.yml` ; les `#if` restent inoffensifs.
