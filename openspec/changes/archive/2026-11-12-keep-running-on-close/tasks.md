# Tasks

## 1. Cycle de vie de l'app

- [x] 1.1 Ajouter dans `App/CairnApp.swift` un `AppDelegate` (`@NSApplicationDelegateAdaptor`) qui renvoie `false` à `applicationShouldTerminateAfterLastWindowClosed` ; vérifier : après ⌘W, le processus Cairn tourne toujours avec 0 fenêtre
- [x] 1.2 Vérifier que relancer l'app sans fenêtre ouverte rouvre la fenêtre principale (`open Cairn.app` : 1 fenêtre)
- [x] 1.3 Vérifier à la main que le clic sur l'icône du Dock rouvre la fenêtre, et que ⌘Q quitte l'app fenêtre fermée en conservant la dernière modification

## 2. Démarrage unique

- [x] 2.1 Ajouter une garde `launched` à `AppState.launch()` pour qu'il ne s'exécute qu'une fois par lancement ; vérifier : le build réussit et la réouverture de la fenêtre ne relance ni purge ni actualisation
