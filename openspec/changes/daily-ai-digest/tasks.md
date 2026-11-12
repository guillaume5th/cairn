# Tasks

## 1. Modèle et logique dans CairnCore

- [x] 1.1 Ajouter le modèle `Digest` (`createdAt`, `text`, `items` JSON de `DigestItem` titre/source/lien, `engine`, valeurs par défaut) et l'enregistrer dans `CairnStore.container` ; vérifier avec un test qui insère et relit un `Digest` en mémoire (items décodés identiques)
- [x] 1.2 Ajouter `Digest.isDue(now:time:lastAttempt:calendar:)` ; vérifier par des tests : avant l'heure → faux, après l'heure sans tentative → vrai, tentative déjà faite aujourd'hui (succès ou échec) → faux, trois jours manqués → vrai une seule fois, heure déplacée dans le passé → vrai
- [x] 1.3 Ajouter `Library.digestArticles(context:now:)` (articles `publishedAt` dans les 24 h précédentes, du plus récent au plus ancien) ; vérifier par un test avec des articles à 1 h, 23 h et 25 h
- [x] 1.4 Ajouter `Library.digestPrompt(for:)` (instructions en français, source + titre + extrait de `plainText` tronqué à ~200 caractères, budget total ~6 000 caractères, au-delà titres seuls puis omission) ; vérifier par des tests : un article court apparaît en entier, 500 articles restent sous le budget
- [x] 1.5 Ajouter `Library.purgeDigests(context:olderThan:now:)` ; vérifier par un test : avec 7 jours, un résumé de 8 jours est supprimé et un de 6 jours reste

## 2. Moteurs d'IA

- [x] 2.1 Ajouter le protocole `Summarizer` et `OllamaSummarizer(baseURL:model:session:)` (`POST /api/generate`, `stream: false`, timeout 300 s, erreurs « serveur Ollama injoignable » et « modèle introuvable » via `CairnError`) ; vérifier par des tests avec `StubProtocol` : réponse lue, corps envoyé correct, 404 → modèle introuvable, connexion refusée → injoignable
- [x] 2.2 Ajouter `AppleSummarizer` (`FoundationModels` : contrôle de `SystemLanguageModel.default.availability` avec un message français par raison, puis `LanguageModelSession.respond`) ; vérifier que `swift build` passe et que la traduction des raisons d'indisponibilité est couverte par un test
- [x] 2.3 Vérifier que l'app sandboxée joint `http://localhost:11434` ; si ATS bloque, ajouter `NSAllowsLocalNetworking` dans `project.yml` (propriétés Info.plist) puis régénérer le projet ; vérifier par un résumé Ollama réel lancé depuis l'app

## 3. Planification dans l'app

- [x] 3.1 Ajouter dans `AppState` `isDigesting` et `makeDigest()` (enregistre `digestLastAttempt`, rafraîchit, sélectionne, s'arrête sans articles, choisit le moteur selon les réglages, insère le `Digest`, purge, enregistre ; erreur → `message`) ; vérifier en lançant l'app : un résumé apparaît, et avec Ollama arrêté l'alerte « serveur Ollama injoignable » s'affiche sans résumé enregistré
- [x] 3.2 Appeler `purgeDigests` dans `launch()` et démarrer après le premier rafraîchissement la boucle qui vérifie `isDue` chaque minute ; vérifier en lançant l'app après l'heure réglée (rattrapage) puis en réglant l'heure une minute plus tard (déclenchement app ouverte)
- [x] 3.3 Ajouter la commande « Générer le résumé maintenant » au menu, grisée pendant `isDigesting` ; vérifier qu'elle produit un résumé même après une tentative du jour

## 4. Interface

- [x] 4.1 Ajouter la scène `Settings` avec `SettingsView` (heure, moteur, adresse et modèle Ollama désactivés hors Ollama, durée 1…90 jours) sur `@AppStorage` avec les valeurs par défaut du design ; vérifier à l'écran via ⌘, que les réglages persistent après relance
- [x] 4.2 Ajouter `SidebarItem.digests` (« Résumés »), la liste des résumés (date + heure, plus récent en tête) et `DigestView` (Markdown puis liens vers les articles ; état vide avec l'heure du prochain résumé) ; vérifier à l'écran qu'un lien ouvre l'article dans le navigateur et que la sélection mémorisée tolère la nouvelle entrée
- [x] 4.4 Permettre de supprimer un résumé (bouton corbeille au-dessus du volet de lecture, comme les actions d'un article, menu contextuel « Supprimer le résumé… » et touche Supprimer dans la liste, avec confirmation) ; vérifier dans l'app qu'après confirmation le résumé disparaît et que le suivant s'affiche, et qu'une annulation le garde
- [x] 4.5 Ajouter `OllamaSummarizer.installedModels()` (`GET /api/tags`, mêmes erreurs que la génération) et remplacer le champ modèle des Réglages par une liste de ces modèles (actualisable, modèle actuel gardé et marqué « non installé » s'il manque, message si serveur injoignable) ; vérifier par un test `StubProtocol` et dans l'app que la liste montre les modèles de `ollama list`
- [x] 4.6 Présenter la conservation comme l'heure (libellé, champ numérique + flèches, « jours »), bornée à 1…90 ; vérifier dans l'app qu'une saisie de 30 est gardée et que 200 devient 90
- [x] 4.7 Ajouter un bouton « Générer un résumé » à droite de la colonne de la liste des résumés, comme les boutons de la liste des articles, grisé pendant un résumé ; vérifier dans l'app qu'il produit un résumé en tête de liste et se grise pendant la génération
- [x] 4.8 Ajouter `Library.search(_:in: [Digest])` et le champ de recherche de la liste des résumés (même emplacement et ⌘F que les articles, vidé au changement d'entrée) et le surlignage (extrait surligné sous chaque ligne via `Library.snippet(for:in: Digest)`, terme surligné dans le résumé affiché) ; vérifier par des tests et dans l'app qu'une recherche filtre la liste et surligne le terme
- [x] 4.3 Mettre à jour le README (résumé quotidien, moteurs, réglages) ; vérifier que la section décrit les valeurs par défaut réelles

## 5. Intégration

- [x] 5.1 Lancer `swift test` dans `CairnCore` et la compilation de l'app ; vérifier que tout passe
- [x] 5.2 Parcourir les scénarios de `specs/daily-digest/spec.md` dans l'app (Apple puis Ollama) ; vérifier que chacun se comporte comme décrit

## Workflow follow-up

- Archiver le change une fois validé (`/opsx:archive`).
