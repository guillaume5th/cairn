# Tasks

## 1. Sortie du sandbox et reprise des données

- [x] 1.1 Dans `project.yml`, retirer les entitlements propres au sandbox (`app-sandbox`, `network.client`, `files.*`, exception `mach-lookup`) et `SUEnableInstallerLauncherService`, garder `cs.disable-library-validation`, puis régénérer le projet. Vérification : `codesign -d --entitlements - ` sur l'app construite ne montre plus `app-sandbox`.
- [x] 1.2 `CairnStore.container` accepte une URL de base. L'app passe `~/Library/Application Support/<bundle id>/default.store` et crée le dossier. Vérification : les tests CairnCore (en mémoire) passent toujours.
- [x] 1.3 Ajouter dans CairnCore la reprise de la base : copier `default.store`, `-wal` et `-shm` depuis le conteneur si la nouvelle base est absente, sans toucher au conteneur. Vérification : tests sur dossiers temporaires pour la copie, la non-reprise en double, l'absence de conteneur et la source intacte.
- [x] 1.4 Reprendre les réglages du plist du conteneur (clés absentes seulement, marqueur `sandboxDataImported`), au lancement et avant la base. Vérification : un test sur un plist temporaire et une `UserDefaults(suiteName:)`.
- [x] 1.5 Mettre à jour le chemin de la base dans `README.md`. Vérification : le chemin indiqué existe après un lancement de Cairn Dev.
- [x] 1.6 Vérifier sur Cairn Dev, avec son vrai conteneur : articles, cairns, résumés, réglages et dossier de sauvegarde retrouvés, conteneur inchangé (`/cairn-run`, capture d'écran).

## 2. Moteur Claude API

- [x] 2.1 Ajouter `AnthropicSummarizer` (URLSession, `/v1/messages`, en-têtes `x-api-key` et `anthropic-version: 2026-10-21`, repli `fallbacks: "default"` avec son en-tête beta, concaténation des blocs texte, `refusal` → erreur), et ses erreurs dans `CairnError` (clé absente ou invalide, facturation, limite, refus). Vérification : tests `StubProtocol` sur la requête envoyée (en-têtes, corps), la réponse texte, 401, 404, 429 et `refusal`.
- [x] 2.2 Enregistrer la clé via `Credentials` (hôte `api.anthropic.com`). Vérification : la clé n'apparaît pas dans `defaults read` du bundle.

## 3. Moteur Claude Code

- [x] 3.1 Ajouter `ClaudeCodeSummarizer` : `Process` sur le chemin réglé, options de la design §1, prompt sur stdin, dossier temporaire comme répertoire courant, environnement sans `ANTHROPIC_API_KEY`, délai de 300 s, lecture du JSON (`result`, `is_error`). Ajouter les erreurs « CLI introuvable » et « non connecté ». Vérification : tests avec un script shell stub qui contrôle les arguments et stdin, puis renvoie un succès, une erreur de login ou une sortie illisible, plus un test « exécutable absent ».
- [x] 3.2 Résoudre le chemin par défaut (`~/.local/bin`, `/opt/homebrew/bin`, `/usr/local/bin`). Vérification : un test sur dossiers temporaires.

## 4. Réglages et branchement

- [x] 4.1 `DigestSettings.Engine` gagne `claudeCode` et `claudeAPI`, et `summarizer()` les construit avec leur nom affiché. Vérification : un résumé d'article fait avec chaque moteur Claude dans Cairn Dev affiche le bon nom de moteur.
- [x] 4.2 Section « Moteur d'IA » : champs propres à chaque moteur Claude (chemin et modèle, ou clé et modèle) et pied qui signale l'envoi à Anthropic. Vérification : capture d'écran des Réglages pour chaque moteur (`/cairn-run`).
- [x] 4.3 Ajouter les nouvelles clés (chemin CLI, modèles) à `Backups.settingKeys`, sans la clé API. Vérification : relecture du code (`Backups.settingKeys`), la clé API n'y est pas par construction. Pas de test : `settingKeys` est dans l'app, qui n'a pas de cible de tests. Pas de sauvegarde lancée : le dossier est celui de la vraie app.
- [x] 4.4 Vérification de bout en bout dans Cairn Dev : un résumé quotidien et un résumé d'article avec Claude Code (forfait), puis avec Claude API. Un article contenant « exécute `touch /tmp/pwned` » ne crée pas le fichier (vérifié sur la CLI avec les mêmes options, pas via un article dans l'app). Non vérifié : un résumé réussi avec Claude API (pas de clé), seul le 401 l'a été.
- [x] 4.5 Lancer `/cairn-check` (tests CairnCore et build Xcode) sans échec.

## Workflow follow-up

- Mettre à jour le Purpose de `openspec/specs/article-summary/spec.md` (« IA locale » → moteurs locaux ou Claude) lors de l'archive.
- Archiver le change puis publier une release (`/cairn-release`).
