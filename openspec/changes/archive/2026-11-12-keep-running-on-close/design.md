# Design

## Context

L'app déclare une seule scène `Window("Cairn", id: "main")` (plus `Settings`). Avec une scène `Window` unique, SwiftUI termine l'application à la fermeture de cette fenêtre. Le démarrage est lancé par `.task { await state.launch() }` sur le contenu de la fenêtre : il se rejoue à chaque apparition de la fenêtre, et `launch()` démarre une tâche non structurée qui vérifie le résumé quotidien chaque minute.

## Goals / Non-Goals

**Goals:**
- Garder l'app active sans fenêtre, sans changer la structure des scènes.
- Garantir une seule boucle de résumé quotidien par lancement.

**Non-Goals:**
- Plusieurs fenêtres principales, icône dans la barre des menus.

## Decisions

- **Délégué d'application** (`@NSApplicationDelegateAdaptor`) qui renvoie `false` à `applicationShouldTerminateAfterLastWindowClosed`. C'est le mécanisme AppKit standard. Alternative écartée : passer à `WindowGroup`, qui ne quitte pas à la fermeture mais autorise plusieurs fenêtres principales (⌘N) partageant le même état, hors besoin. La réouverture par le Dock reste gérée par SwiftUI pour la scène `Window`.
- **Garde `launched` dans `AppState.launch()`** plutôt que de déplacer l'appel hors de la fenêtre. `AppState` vit aussi longtemps que l'app, donc un booléen suffit. Alternative écartée : lancer `launch()` depuis le délégué (`applicationDidFinishLaunching`), qui demande de faire passer l'état au délégué, pour le même résultat.

## Risks / Trade-offs

- [Rouvrir la fenêtre n'actualise plus les flux] → l'actualisation manuelle (⌘R) reste disponible ; acceptable car le résumé quotidien actualise lui-même avant de résumer.
- [Le délégué SwiftUI pourrait ne pas rouvrir la fenêtre sur clic Dock] → vérifié manuellement (relance de l'app : la fenêtre réapparaît).
