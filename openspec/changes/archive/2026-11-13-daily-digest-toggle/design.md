# Design

## Context

Une boucle lancée par `AppState.launch()` vérifie chaque minute `DigestSettings.isDue` et appelle `makeDigest()` ; le premier passage, juste après le rafraîchissement du lancement, fait le rattrapage. La génération à la demande appelle `makeDigest(manual: true)` sans passer par `isDue`. Les réglages du résumé sont des `@AppStorage` lus par `DigestSettings`. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Un seul point de décision pour tout ce qui est automatique.

**Non-Goals:**
- Arrêter la boucle de planification quand le réglage est désactivé : elle ne coûte qu'une lecture de réglage par minute.
- Masquer l'entrée « Résumés quotidiens » ou la génération à la demande (choix de l'utilisateur).

## Decisions

- **Nouvelle clé `digestEnabled`, vraie par défaut**, lue comme `defaults.object(forKey:) as? Bool ?? true` : les installations existantes gardent le résumé automatique sans migration.
- **`DigestSettings.isDue` renvoie faux quand la clé est fausse.** L'heure réglée et le rattrapage au lancement passent tous deux par la boucle, donc par `isDue` ; la génération manuelle n'y passe pas et reste disponible. Comme la boucle relit le réglage chaque minute, le réactiver après l'heure produit le résumé du jour dans la minute, sans code supplémentaire, comme un changement d'heure. Alternative écartée : un test dans `makeDigest`, qui aurait demandé de distinguer l'appel manuel.
- **Notifications** : elles ne concernent que les résumés automatiques, donc il n'y en a plus quand le réglage est désactivé, sans toucher à `DigestNotifications`.
- **Réglages : interrupteur en tête de la section Résumé quotidien ; l'heure et la notification sont grisées (`.disabled`) plutôt que masquées.** La fenêtre des Réglages s'ajuste à son contenu : masquer ferait changer sa hauteur à chaque bascule. La durée de conservation reste active, elle s'applique aussi aux résumés manuels. Le texte de pied de section dit qu'aucun résumé n'est produit automatiquement et qu'on peut en générer un depuis la liste.
- **Volet sans résumé** : « Résumé automatique désactivé. » à la place de « Prochain résumé à … ».

## Risks / Trade-offs

- [Réactiver tard dans la journée produit aussitôt un résumé des dernières 24 heures] → même règle que le rattrapage au lancement et le changement d'heure, déjà dans la spec.
- [Pas de test automatisé de l'interface] → vérifications dans Cairn Dev, voir tasks.md.
