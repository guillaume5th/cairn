# Design

## Context

Voir proposal.md (Why) et specs/daily-digest/spec.md. L'app est un client RSS macOS 27 en SwiftUI + SwiftData (schéma compatible CloudKit, mais pas de conteneur iCloud aujourd'hui). La logique métier vit dans `CairnCore` (`Library`, testée par `LibraryTests` avec `StubProtocol` pour le réseau) ; `AppState` orchestre lancement, rafraîchissement et messages d'erreur. Les réglages par Mac sont dans `UserDefaults` (`@AppStorage`, cf. `TextScale`). L'app est sandboxée avec `network.client`.

## Goals / Non-Goals

**Goals:**
- Logique (sélection, prompt, échéance, purge, moteur Ollama) dans `CairnCore`, testable sans IA réelle.
- Aucune nouvelle dépendance.

**Non-Goals:**
- Exécution quand l'app est fermée (pas de login item / LaunchAgent).
- Notification système quand le résumé est prêt.
- Résumé par dossier ou par cairn ; streaming du texte ; moteurs distants (Claude, OpenAI).
- Synchronisation des résumés entre Macs.

## Decisions

**Modèle `Digest` (SwiftData).** Champs : `createdAt: Date`, `text: String` (Markdown produit par le moteur), `items: Data` (JSON `[DigestItem]` : titre, source, lien), `engine: String`. Valeurs par défaut partout, comme les autres modèles. Les articles sont copiés plutôt que reliés : ils sont purgés à 30 jours indépendamment, et une relation plusieurs-à-plusieurs n'apporte rien ici. Ajouté à `CairnStore.container` (migration légère automatique : nouvelle entité).

**Échéance calculée, pas mémorisée en base.** `UserDefaults["digestLastAttempt"]` contient la date de la dernière tentative (succès, aucun article ou échec). Fonction pure dans `CairnCore` : `Digest.isDue(now:, time:, lastAttempt:, calendar:) -> Bool` = « l'heure réglée d'aujourd'hui est passée et `lastAttempt` est antérieur à elle ». Cela couvre le rattrapage, les jours manqués (un seul résumé) et le changement d'heure. Alternative écartée : chercher en base un `Digest` du jour — ne marque ni les échecs ni les jours sans article, donc relance en boucle.

**Planification : vérification chaque minute.** Une `Task` lancée par `AppState.launch()` après le premier rafraîchissement boucle `while true { if due { await makeDigest() }; try await Task.sleep(for: .seconds(60)) }`. Plus simple et plus robuste qu'un sleep jusqu'à l'heure exacte (veille, changement de fuseau ou d'heure réglée). Coût négligeable.

**Production (`AppState.makeDigest()`).** Garde `isDigesting` (grise la commande). Enregistre la tentative, appelle `refresh()`, sélectionne les articles `publishedAt` dans `(now − 24 h, now]` via `Library.digestArticles(context:now:)`, et s'arrête sans appeler l'IA si la liste est vide. Sinon construit le prompt, appelle le moteur, insère le `Digest`, purge, enregistre. Erreur → `message` (alerte existante).

**Moteurs : protocole minimal.** `protocol Summarizer { func summarize(_ prompt: String) async throws -> String }` dans `CairnCore`.
- `AppleSummarizer` : `FoundationModels` — vérifie `SystemLanguageModel.default.availability` et traduit chaque raison d'indisponibilité en message français, puis `LanguageModelSession(instructions:).respond(to:)`.
- `OllamaSummarizer(baseURL:, model:, session: URLSession)` : `POST {baseURL}/api/generate` avec `{"model", "prompt", "stream": false}`, lit `response`. Erreurs : connexion refusée → « serveur Ollama injoignable », HTTP 404 → « modèle introuvable ». `URLSession` injectable pour les tests avec `StubProtocol`.
Alternative écartée : un seul moteur. L'utilisateur veut Apple par défaut et Ollama en option.

**Prompt.** Instructions : « Résume en français les articles suivants, regroupe les sujets proches, en Markdown, sans inventer. » Puis une ligne par article : source, titre, extrait (`Library.plainText` du contenu, tronqué). Le budget du modèle Apple est petit (fenêtre de contexte de quelques milliers de tokens) : l'extrait est limité à ~200 caractères et le prompt total à ~6 000 caractères (fenêtre de 4 096 tokens, réponse comprise) ; au-delà, les articles restants n'apportent que source et titre, puis sont omis du prompt (mais restent dans la liste affichée). Même prompt pour Ollama, pour garder un seul chemin. La liste d'articles affichée sous le résumé est construite par le code, pas par le modèle : liens toujours justes.

**Réglages.** `@AppStorage` : `digestTime` (minutes depuis minuit, défaut 480), `digestEngine` (`apple` | `ollama`), `ollamaURL` (défaut `http://localhost:11434`), `ollamaModel` (défaut `llama3.2`), `digestRetentionDays` (défaut 7, 1…90). Nouvelle scène `Settings { SettingsView() }` (⌘, fourni par SwiftUI) : `DatePicker(.hourAndMinute)`, `Picker` du moteur, un `TextField` pour l'adresse et un `Picker` des modèles installés (`GET /api/tags`, relu par `.task(id:)` sur moteur + adresse, et par un bouton Actualiser) désactivés hors Ollama ; la durée en `TextField(value:format: .number)` + `Stepper` sans libellé, comme le champ d'heure du `DatePicker`.

**Purge.** `Library.purgeDigests(context:, olderThan days:, now:)` sur `createdAt`, appelée au lancement (à côté de `purge`) et après chaque résumé.

**Affichage.** `SidebarItem.digests` (une ligne « Résumés » sous « Tous les articles »). Dans `ContentView`, quand cette entrée est sélectionnée, la colonne du milieu liste les `Digest` (`@Query` triée par `createdAt` décroissant, libellé date + heure) et le détail affiche `DigestView` : `Text(AttributedString(markdown:))` du texte, puis les `DigestItem` en `Link`. Vide : « Prochain résumé à HH:MM ». La commande « Générer le résumé maintenant » est ajoutée au menu Présentation à côté de « Rafraîchir ».

## Risks / Trade-offs

- [Fenêtre de contexte du modèle Apple] → prompt borné par caractères ; les jours très chargés sont résumés surtout par titres. Ollama ne profite pas d'un budget plus grand (shortcut, à élargir si besoin).
- [ATS bloque `http://localhost`] → vérifier à l'implémentation ; vérifié : l'app sandboxée joint `http://localhost` sans exception ATS.
- [Mac en veille à l'heure prévue] → la boucle détecte l'échéance à la première minute après le réveil.
- [Réponse lente d'Ollama] → timeout `URLRequest` porté à 300 s ; la commande reste grisée pendant ce temps.
- [Si CloudKit est activé plus tard] → chaque Mac produirait son propre résumé, dupliqué par la synchro. Hors périmètre aujourd'hui.

## Migration Plan

Nouvelle entité SwiftData : migration légère automatique, rien à faire. Retour arrière : retirer `Digest` du conteneur supprime l'entité.
