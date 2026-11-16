# Design

## Context

Les moteurs partagent le protocole `Summarizer` (`CairnCore/Sources/CairnCore/Summarizer.swift`). `DigestSettings.summarizer()` (`App/DigestViews.swift`) choisit le moteur d'après `UserDefaults` et renvoie aussi son nom affiché. Résumé quotidien et résumé d'article passent tous les deux par là, donc un moteur ajouté sert aux deux.

Cairn est sandboxée et signée ad hoc. Le sandbox empêche deux choses : exécuter `~/.local/bin/claude`, et laisser ce processus lire son login (dans `~/.claude` et le trousseau). Un enfant lancé par une app sandboxée hérite de son sandbox. La base SwiftData et les réglages vivent dans `~/Library/Containers/<bundle id>/Data/…`. Hors sandbox, l'app ne les voit plus.

## Goals / Non-Goals

**Goals:**
- Deux moteurs Claude interchangeables avec les deux moteurs locaux, sans toucher aux appelants.
- Aucun outil côté Claude Code : le contenu d'un article ne doit pas pouvoir déclencher d'action sur le Mac.
- Sortie du sandbox sans perte de données, et retour possible à l'ancienne version.

**Non-Goals:**
- Streaming du résumé : l'interface attend déjà le texte complet.
- Réutiliser le token OAuth du forfait directement depuis Cairn. Les conditions d'Anthropic l'interdisent, d'où le passage par la CLI.
- Gestion de plusieurs clés API ou de plusieurs comptes.

## Decisions

**1. Claude Code : lancer la CLI avec `Process`, tous les outils coupés.**
Commande : `claude -p --output-format json --tools "" --strict-mcp-config --disable-slash-commands --no-session-persistence --setting-sources ""`, plus `--model <m>` si un modèle est réglé. Le prompt passe sur stdin (pas de limite de taille d'argument). Le répertoire courant est un dossier temporaire vide.
- `--tools ""` et `--strict-mcp-config` sans config : aucun outil intégré ni MCP. Ça répond au scénario « article qui tente de détourner Claude Code ».
- `--setting-sources ""` : ni les hooks ni les réglages de l'utilisateur ne s'appliquent (par exemple les hooks qui réécrivent les commandes).
- Pas de `--bare` : ce mode saute la lecture du trousseau et n'accepte qu'`ANTHROPIC_API_KEY`, donc il ne marcherait pas avec le forfait.
- `ANTHROPIC_API_KEY` est retirée de l'environnement de l'enfant, pour qu'il utilise forcément le compte connecté.
- On lit la réponse JSON : `result` si `is_error` vaut false. Sinon, un message qui parle de login donne l'erreur « non connecté », et tout autre échec donne le texte de l'erreur. Délai de 300 s, puis `terminate()`.
- Le chemin de la CLI se règle. Par défaut, c'est le premier qui existe parmi `~/.local/bin/claude`, `/opt/homebrew/bin/claude` et `/usr/local/bin/claude`. Une app graphique n'hérite pas du `PATH` du shell.
- Alternative écartée : le Claude Agent SDK. Il n'existe pas en Swift et ajouterait Node ou Python.

**2. Claude API : HTTP brut avec `URLSession`.**
Il n'y a pas de SDK Anthropic officiel en Swift, donc HTTP brut, sur le modèle d'`OllamaSummarizer`. La requête : `POST https://api.anthropic.com/v1/messages` avec les en-têtes `x-api-key`, `anthropic-version: 2026-10-21` et `content-type: application/json`. Le corps contient `model`, `max_tokens: 16000` et un seul message `user`.
- Le modèle se règle, par défaut `claude-haiku-5-5` (résumer est une tâche légère et l'API est facturée au token). L'utilisateur peut choisir `claude-sonnet-5-5` ou `claude-opus-5-5`.
- Repli serveur en cas de refus : en-tête `anthropic-beta: server-side-fallback-2026-07-01` et `fallbacks: "default"`. On vérifie `stop_reason` : `refusal` devient une erreur explicite.
- Le texte est la concaténation des blocs `type == "text"`.
- Les erreurs HTTP correspondent aux messages des Réglages : 401 → clé invalide, 402 → facturation, 404 → modèle introuvable, 429 et 529 → limite atteinte ou service surchargé, le reste → `httpStatus`.

**3. Clé API dans le trousseau, avec `Credentials`.**
On réutilise `Credentials.save/login/remove` avec l'hôte `api.anthropic.com` (service « Cairn — api.anthropic.com »). C'est le même mécanisme que les logins de sites, sans nouveau code de trousseau. La clé n'entre jamais dans `UserDefaults`, donc jamais dans `Backups.settingKeys`.

**4. Sortie du sandbox.**
- `project.yml` : on retire `app-sandbox`, `network.client`, `files.user-selected.read-write`, `files.bookmarks.app-scope` et l'exception `mach-lookup`, qui n'ont de sens que sous sandbox. On garde `cs.disable-library-validation`, nécessaire pour Sparkle en signature ad hoc. Dans l'Info.plist, on retire `SUEnableInstallerLauncherService`.
- La base a un emplacement explicite : `~/Library/Application Support/<bundle id>/default.store`. Le dossier par défaut hors sandbox serait `~/Library/Application Support/default.store`, partagé avec d'autres apps et commun à Cairn et Cairn Dev. Le bundle id garde la séparation Dev/prod que les conteneurs assuraient. `CairnStore.container` prend une URL optionnelle, et les tests restent en mémoire.

**5. Reprise depuis le conteneur, au lancement, avant d'ouvrir la base.**
Une fonction de CairnCore, testable avec deux dossiers temporaires, fait ceci : si la nouvelle base n'existe pas et que `~/Library/Containers/<bundle id>/Data/Library/Application Support/default.store` existe, elle copie `default.store`, `-wal` et `-shm`. Elle copie sans déplacer : l'ancien conteneur reste intact, et une rétrogradation retrouve ses données.
Pour les réglages : si `UserDefaults` n'a pas encore la clé `sandboxDataImported`, on lit `…/Containers/<bundle id>/Data/Library/Preferences/<bundle id>.plist` et on recopie chaque clé absente, puis on pose `sandboxDataImported`. Le signet du dossier de sauvegarde en fait partie. Un signet à portée de sécurité se résout aussi hors sandbox (`startAccessingSecurityScopedResource` renvoie alors false, ce qui ne pose pas de problème).

**6. Réglages.**
`DigestSettings.Engine` gagne `claudeCode` et `claudeAPI`. Comme pour Ollama, seuls les champs du moteur choisi s'affichent :
- Claude Code : chemin de la CLI, modèle.
- Claude API : `SecureField` de clé (enregistrée dans le trousseau à la validation), modèle.

Les deux menus de modèle sont identiques : Haiku (par défaut), Sonnet, Opus. Claude Code stocke l'alias (`haiku`, `sonnet`, `opus`), l'API l'identifiant complet.

Le pied de section dit que le contenu des articles résumés est envoyé à Anthropic. Les noms affichés sont « Claude Code (<modèle>) » et « Claude API (<modèle>) ». Les nouvelles clés de `UserDefaults` (chemin CLI, modèles) vont dans `Backups.settingKeys`.

## Risks / Trade-offs

- [Sortie du sandbox : Cairn peut tout lire dans le compte utilisateur] → C'est un choix explicite de l'utilisateur. Les outils de Claude Code restent coupés, donc un article ne peut rien déclencher.
- [Le format JSON ou les options de la CLI changent d'une version à l'autre] → Si l'analyse échoue, on affiche le message brut au lieu d'échouer en silence. Les options utilisées sont documentées dans `claude --help`.
- [La détection de « non connecté » repose sur le texte de l'erreur] → shortcut. Au pire, le message brut de la CLI s'affiche, ce qui reste compréhensible.
- [Le signet de sauvegarde ne se résout pas hors sandbox] → La section Sauvegarde affiche déjà le dossier comme introuvable, et l'utilisateur le choisit de nouveau.
- [Coût : Opus 5.5 reste choisissable sur l'API, 40 fois plus cher que Haiku 5.5] → Haiku est le défaut, et le modèle se règle.
- [Les articles partent chez Anthropic] → L'avertissement est dans les Réglages, et aucun moteur Claude n'est choisi par défaut.

## Migration Plan

1. La version hors sandbox se publie avec la release habituelle. Sparkle installe sans le launcher service, puisque l'app n'est plus sandboxée.
2. Au premier lancement, la reprise copie la base et les réglages.
3. Retour arrière : réinstaller la version précédente. Elle relit son conteneur, qui n'a pas été touché, mais perd ce qui a été fait depuis.
4. Avant la release, vérifier sur Cairn Dev (`dev.cairn.Cairn.debug`, données jetables) que la reprise fonctionne avec un vrai conteneur.
