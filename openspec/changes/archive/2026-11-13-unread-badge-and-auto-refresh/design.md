# Design

## Context

`AppState.launch()` rafraîchit une fois puis lance une boucle qui, chaque minute, vérifie si le résumé quotidien est dû. `AppState.refresh()` ignore un appel pendant un rafraîchissement en cours. Le nombre de non-lus de « Tous les articles » vient d'une `@Query` de `SidebarView`, qui n'existe que fenêtre ouverte ; fenêtre fermée, l'app tourne encore (app-lifecycle) et seul un rafraîchissement peut changer ce nombre. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Badge juste fenêtre ouverte ou fermée, sans tâche de fond supplémentaire.
- Rafraîchissement automatique qui survit à la veille et aux changements de réglage, comme le résumé quotidien.

**Non-Goals:**
- Rafraîchissement en arrière-plan quand l'app est quittée (pas d'agent ni de tâche planifiée système).
- Fréquence par abonnement, ou respect des indications de fréquence des flux (`ttl`, `Cache-Control`).
- Notifications de nouveaux articles.

## Decisions

- **Une boucle d'une minute, comme le résumé.** Elle compare `Date.now` à `lastRefresh + intervalle` et appelle `refresh()` quand c'est dépassé. Elle relit le réglage à chaque tour : un changement de fréquence s'applique dans la minute, et la sortie de veille aussi. Alternative écartée : un `Task.sleep` de la durée de l'intervalle, qui ne voit ni la veille ni un changement de réglage. Elle est lancée dans `launch()` après le premier rafraîchissement, à côté de la boucle du résumé, mais séparée d'elle : le résumé appelle lui-même `refresh()`, et les deux restent indépendants.
- **`lastRefresh` en mémoire dans `AppState`**, mis à jour à la fin de `refresh()`, donc aussi par ⌘R, le lancement et le résumé. Pas besoin de le stocker : chaque lancement rafraîchit.
- **Réglage `refreshInterval` en minutes** (`@AppStorage`, entier), 30 par défaut, 0 pour Jamais. `Picker` « Rafraîchir les abonnements » dans une nouvelle section en tête des Réglages, au-dessus d'Affichage : il concerne les abonnements, pas l'affichage.
- **Le badge passe par `NSApp.dockTile.badgeLabel`**, l'API native du badge d'app. Une seule fonction `AppState.updateBadge(unread:)` prend le nombre de non-lus de la barre latérale quand elle le fournit, sinon le lit avec `context.fetchCount` (même prédicat que sa `@Query`), et met `badgeLabel` à `nil` à zéro ou si le réglage `showsDockBadge` est désactivé. Constaté à l'implémentation : `fetchCount` ne voit pas un marquage pas encore sauvegardé, d'où le nombre passé par la barre latérale.
- **Autorisation des pastilles.** Constaté à l'implémentation : macOS n'affiche pas `badgeLabel` sans l'autorisation `.badge` des notifications. `DigestNotifications.requestAuthorization()` demande désormais `.alert`, `.sound` et `.badge` en une fois : macOS ne pose la question qu'une fois, une option ajoutée plus tard ne serait jamais proposée. Elle est appelée au lancement quand le badge est activé (donc au premier lancement, valeur par défaut) et quand l'utilisateur active l'interrupteur. Les alertes restent gouvernées par « Me prévenir quand le résumé est prêt ». Un refus (`badgeSetting == .disabled`) affiche un texte de pied de section dans Affichage, comme pour la notification du résumé.
- **Quand le badge est mis à jour :** à la fin de chaque `refresh()` (couvre la fenêtre fermée et le lancement) ; dans `SidebarView` sur `onChange` du nombre de non-lus (lecture, marquage, suppression, fenêtre ouverte) ; et quand l'interrupteur change dans les Réglages. Alternative écartée : observer les sauvegardes de `ModelContext`, qui arrivent en différé avec l'autosauvegarde et n'apportent rien de plus.
- **Interrupteur « Badge sur l'icône »** dans la section Affichage, clé `showsDockBadge`, vrai par défaut.

## Risks / Trade-offs

- [Une demande d'autorisation de notifications dès le premier lancement] → choix de l'utilisateur, pour un badge activé par défaut ; la demande couvre aussi la notification du résumé, qui n'en refera pas.

- [Un rafraîchissement automatique qui échoue affiche l'alerte d'erreur de l'app, toutes les 30 minutes si l'échec persiste] → `refreshAll` isole déjà les erreurs par flux et ne lève que pour une erreur de stockage, rare ; un réseau coupé ne déclenche pas d'alerte.
- [L'indicateur de rafraîchissement de la barre d'outils tourne aussi pendant un rafraîchissement automatique] → voulu : c'est le même rafraîchissement, et ⌘R est ignoré pendant ce temps.
- [Un marquage fait fenêtre fermée (aucun ne l'est aujourd'hui) ne mettrait pas le badge à jour avant le rafraîchissement suivant] → aucune action de lecture n'existe sans fenêtre.
- [Pas de test automatisé de l'interface] → vérifications dans Cairn Dev, voir tasks.md.
