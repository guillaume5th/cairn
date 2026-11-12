# Tasks

## 1. Tentative du résumé comptée seulement quand le moteur a travaillé

- [x] 1.1 Dans `AppState.makeDigest()`, noter `digestLastAttempt` après l'appel au moteur (succès ou échec ordinaire), plus avant ; ne pas le noter quand le travail est annulé ou que le moteur est indisponible pour cause d'arrière-plan. Vérifier par un test (DigestTests) qu'une annulation laisse le résumé dû
- [x] 1.2 Vérifier sur Mac que le résumé manuel et le résumé automatique se comportent comme avant (une seule tentative par jour, message en cas d'échec)

## 2. Notification du résumé prêt (Mac et iOS)

- [x] 2.1 Ajouter `DigestSettings.notifyKey` et l'interrupteur « Me prévenir quand le résumé est prêt » dans la section Résumé quotidien des Réglages, avec demande d'autorisation à l'activation et retour à désactivé si refusée ; vérifier les deux cas sur le simulateur iPhone et sur Mac
- [x] 2.2 Envoyer la notification locale depuis `makeDigest()` pour un résumé automatique réussi quand l'app n'est pas active ; vérifier sur Mac, fenêtre fermée, avec une heure de résumé réglée à la minute suivante
- [x] 2.3 Délégué de notifications : toucher la notification ouvre « Résumés quotidiens » sur ce résumé (et rouvre la fenêtre sur Mac) ; vérifier sur Mac et sur iPhone

## 3. Arrière-plan iOS

- [x] 3.1 Ajouter dans `project.yml` (cible iOS) `UIBackgroundModes: [fetch, processing]` et `BGTaskSchedulerPermittedIdentifiers: [dev.cairn.refresh, dev.cairn.digest]`, régénérer avec XcodeGen et vérifier les clés dans l'Info.plist produit
- [x] 3.2 Déclarer `.backgroundTask(.appRefresh("dev.cairn.refresh"))` pour rafraîchir (toutes les heures) et `.backgroundTask(.processingTask("dev.cairn.digest"))` pour le résumé (à partir de son heure) ; les reprogrammer au passage en arrière-plan et à la fin de chaque tâche au passage en arrière-plan et à la fin de chaque tâche. Vérifier sur le simulateur avec `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"dev.cairn.refresh"]` dans le débogueur
- [x] 3.3 Mesurer sur un vrai iPhone si le moteur d'Apple répond dans la tâche ; selon le résultat, confirmer que la tentative n'est pas comptée et que le résumé est produit au retour dans l'app
- [x] 3.4 Mettre à jour le README (section iPhone et iPad : résumé en arrière-plan « au mieux », réglage d'actualisation en arrière-plan d'iOS) et vérifier le rendu

## 4. Vérification d'ensemble

- [x] 4.1 Installer sur iPhone et iPad, régler le résumé quelques minutes plus tard, mettre l'app en arrière-plan, et vérifier le résumé et la notification ; noter le résultat dans la PR
- [x] 4.2 `openspec validate add-background-digest --strict` passe

## Workflow follow-up

- Archiver le changement une fois la PR fusionnée, avec synchronisation des specs `daily-digest` et `ios-app`.
