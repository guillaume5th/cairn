# Proposal

## Why

Les modèles locaux (Apple Intelligence, Ollama) donnent des résumés moyens. L'utilisateur a un forfait Claude Team et veut s'en servir pour les résumés, et aussi pouvoir passer par une clé API Anthropic.

## What Changes

- Deux nouveaux moteurs d'IA dans les Réglages, en plus d'Apple Intelligence et Ollama :
  - **Claude Code** : Cairn lance la CLI `claude` installée sur le Mac, en mode non interactif et sans aucun outil. Le résumé passe par le compte connecté dans Claude Code (le forfait Team), sans clé à saisir.
  - **Claude (API)** : Cairn appelle l'API Messages d'Anthropic avec une clé API saisie dans les Réglages et gardée dans le trousseau macOS. C'est facturé à l'usage, hors forfait.
- Pour ces deux moteurs, le contenu des articles part chez Anthropic. Les Réglages le disent, et ces moteurs ne sont jamais choisis par défaut.
- **BREAKING (technique)** : Cairn quitte l'App Sandbox. Une app sandboxée ne peut ni lancer `~/.local/bin/claude` ni lui laisser lire son login. Au premier lancement hors sandbox, Cairn reprend sa base, ses réglages et son dossier de sauvegarde depuis l'ancien conteneur, sans rien supprimer.
- La config Sparkle propre au sandbox (installer launcher, exceptions mach-lookup) est retirée.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `daily-digest` : « Choix du moteur d'IA » passe de deux à quatre moteurs, et la règle « le contenu n'est envoyé à aucun autre service » devient propre aux moteurs locaux. « Échec du résumé » ajoute les causes propres à Claude.
- `article-summary` : « Résumer l'article consulté » cite les quatre moteurs.
- `app-lifecycle` : nouvelle exigence, reprendre les données de l'ancien conteneur sandbox au premier lancement.

## Impact

- `CairnCore/Sources/CairnCore/Summarizer.swift` : `ClaudeCodeSummarizer` (Process) et `AnthropicSummarizer` (URLSession), avec tests sur stubs.
- `CairnCore/Sources/CairnCore/CairnError.swift` : nouvelles erreurs (CLI introuvable, CLI non connectée, clé absente ou invalide, quota, refus).
- `CairnCore/Sources/CairnCore/Models.swift` : emplacement explicite de la base hors conteneur.
- `App/DigestViews.swift` : choix du moteur, réglages Claude, mention de l'envoi chez Anthropic.
- `App/Credentials.swift` : stockage de la clé API.
- `App/Backups.swift` : nouvelles clés de réglage sauvegardées (jamais la clé API).
- `project.yml` / `App/Cairn.entitlements` : sandbox retiré, config Sparkle simplifiée.
- Migration au lancement (`App/CairnApp.swift` ou `AppState`), et `README.md` (chemin de la base).
