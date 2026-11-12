# Design

## Context

- `AppState.launch()` lance une boucle qui vérifie chaque minute `DigestSettings.isDue` puis appelle `makeDigest()`. Cette fonction note la tentative (`digestLastAttempt`) avant même de rafraîchir, quel que soit le résultat.
- Sur Mac, l'app continue de tourner fenêtre fermée (`AppDelegate`), donc la boucle suffit à produire le résumé. Il ne manque que la notification.
- Sur iOS, l'app est suspendue en arrière-plan, et la boucle s'arrête avec elle.
- Les deux moteurs ont des contraintes différentes. Ollama est un appel HTTP, faisable en arrière-plan dans le temps accordé. Le modèle d'Apple (FoundationModels) n'est pas garanti hors premier plan.

## Goals / Non-Goals

**Goals:**
- Réutiliser `refresh()` et `makeDigest()` tels quels depuis une tâche d'arrière-plan iOS.
- Une seule notification par résumé automatique, avec un lien profond vers ce résumé.

**Non-Goals:**
- Lancer Cairn à l'ouverture de session sur Mac, ou produire le résumé quand l'app est quittée.
- Notifier les nouveaux articles : seul le résumé quotidien déclenche une notification.
- Notifications distantes (push) ou serveur : tout reste sur l'appareil.

## Decisions

1. **Deux tâches iOS sur la `WindowGroup`.** `.backgroundTask(.appRefresh("dev.cairn.refresh"))` rafraîchit les abonnements, environ toutes les heures. `.backgroundTask(.processingTask("dev.cairn.digest"))` produit le résumé : il rafraîchit, résume s'il est dû, enregistre. Les deux sont reprogrammées au passage en arrière-plan et à la fin de chaque tâche. La tâche du résumé part au plus tôt à l'heure réglée (tout de suite s'il est dû), avec réseau requis mais sans exiger la recharge.
   - *Pourquoi pas une seule actualisation :* elle dure environ 30 s, et le modèle d'Apple est bien plus lent en arrière-plan qu'au premier plan. Mesuré sur iPad : 11 s au premier plan, plus de 25 s en arrière-plan pour 4 articles, donc coupé. Sur iPhone : 26 s, de justesse.
   - *Compromis :* iOS lance une tâche de traitement quand l'appareil est au repos. Le résumé arrive donc souvent un peu après l'heure réglée, pas à la minute près.
2. **Une tentative en arrière-plan ne compte que si le moteur a réellement pu travailler.** `makeDigest()` ne notera plus la tentative en premier : il la notera après l'appel au moteur, qu'il réussisse ou échoue pour une raison « normale » (Ollama injoignable, erreur du modèle). Une indisponibilité liée à l'arrière-plan ne la note pas : modèle d'Apple refusé hors premier plan, ou temps accordé expiré. Le rattrapage au retour dans l'app s'en charge alors.
   - *Alternative :* forcer Ollama en arrière-plan et toujours différer le modèle d'Apple. C'est plus simple, mais cela supposerait le comportement d'Apple sans le vérifier.
3. **Notification locale (`UNUserNotificationCenter`), envoyée par `makeDigest()` quand trois conditions sont réunies :** le résumé n'est pas manuel, il a réussi, et la scène n'est pas active (Mac : `NSApp.isActive == false` ; iOS : `scenePhase != .active`). Le titre est « Ton résumé du jour est prêt », le corps reprend la première ligne utile du résumé, et `userInfo` contient l'identifiant du résumé.
4. **Lien profond :** le délégué de notifications enregistre l'identifiant dans `AppState`. `ContentView` sélectionne alors l'entrée « Résumés quotidiens » et le résumé, comme le fait déjà la sélection mémorisée par entrée. Sur Mac, l'action rouvre aussi la fenêtre (`openWindow(id: "main")`).
5. **Réglage `DigestSettings.notifyKey`, désactivé par défaut.** La demande d'autorisation (`requestAuthorization(options: [.alert, .sound])`) n'a lieu qu'au moment où l'utilisateur active l'interrupteur, pas au lancement.

## Risks / Trade-offs

- **[Risque]** iOS accorde du temps d'arrière-plan selon l'usage de l'app, et parfois pas du tout. → Le rattrapage au retour dans l'app reste en place, et la spec ne promet aucune heure.
- **[Risque]** Même une tâche de traitement peut expirer sur un très long prompt. → `expirationHandler` annule la tâche sans noter la tentative, et le résumé est refait au premier plan.
- **[Risque]** L'enregistrement SwiftData en arrière-plan peut être interrompu. → Enregistrer avant de finir la tâche, comme le fait déjà le passage en `.background`.
- **[Compromis]** Pas de notification quand l'app est au premier plan, pour ne pas faire doublon avec la liste des résumés qui se met à jour.

## Migration Plan

- Aucune migration de données : le réglage est désactivé par défaut et la clé `digestLastAttempt` ne change pas.
- Retour arrière : retirer la tâche d'arrière-plan suffit à revenir au comportement actuel.

## Open Questions

- Résolu : FoundationModels répond en arrière-plan, mais trop lentement pour une actualisation (voir décision 1).
