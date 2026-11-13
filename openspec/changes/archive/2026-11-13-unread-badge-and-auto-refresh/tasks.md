# Tasks

## 1. Rafraîchissement automatique

- [x] 1.1 Ajouter `lastRefresh` à `AppState`, mis à jour à la fin de `refresh()`, et la clé `refreshInterval` (minutes, 30 par défaut, 0 = Jamais)
- [x] 1.2 Lancer dans `launch()` une boucle d'une minute qui appelle `refresh()` quand l'intervalle est écoulé depuis `lastRefresh` et que la fréquence n'est pas Jamais ; vérifier dans Cairn Dev avec 15 minutes, puis qu'avec Jamais aucun rafraîchissement automatique n'a lieu
- [x] 1.3 Vérifier qu'en passant de 30 à 15 minutes 20 minutes après le dernier rafraîchissement, un rafraîchissement a lieu dans la minute, et que la boucle tourne fenêtre fermée
- [x] 1.4 Ajouter le `Picker` « Rafraîchir les abonnements » (Jamais, 15 min, 30 min, 1 h, 2 h) dans une section en tête de `SettingsView` ; vérifier sur capture

## 2. Badge du Dock

- [x] 2.1 Ajouter `AppState.updateBadge()` (non-lus via `fetchCount`, réglage `showsDockBadge` vrai par défaut, `nil` à zéro) et l'appeler à la fin de `refresh()`
- [x] 2.2 Appeler `updateBadge()` depuis `SidebarView` quand le nombre de non-lus change ; vérifier dans Cairn Dev que lire un article ou « Marquer tout comme lu » met le badge à jour, et qu'il disparaît à zéro
- [x] 2.3 Ajouter l'interrupteur « Badge sur l'icône » dans la section Affichage de `SettingsView`, qui met le badge à jour aussitôt ; vérifier sur capture du Dock
- [x] 2.4 Demander l'autorisation des pastilles (`.badge` ajouté à `DigestNotifications.requestAuthorization()`) au lancement quand le badge est activé et quand on active l'interrupteur ; afficher dans Affichage un texte quand elles sont refusées ; vérifier que le badge apparaît une fois l'autorisation donnée

## 3. Intégration

- [x] 3.1 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`
