# Proposal

## Why

Chaque nouvelle version de Cairn s'installe à la main : télécharger le DMG de la release, remplacer l'app. On rate des versions, et les corrections arrivent tard.

## What Changes

- Cairn intègre Sparkle 2 : il vérifie les mises à jour automatiquement (une fois par jour) et propose « Rechercher les mises à jour… » dans le menu Cairn.
- Une mise à jour trouvée s'affiche avec la fenêtre standard de Sparkle ; installée, Cairn redémarre sur la nouvelle version.
- Chaque release publie, à côté du DMG, un `appcast.xml` signé (EdDSA) ; l'app lit `releases/latest/download/appcast.xml` du dépôt GitHub, qui doit être public.
- Cairn Dev ne se met jamais à jour (il serait remplacé par l'app de release).

## Capabilities

### New Capabilities

- `app-updates` : mises à jour de l'app par Sparkle.

### Modified Capabilities

Aucune.

## Impact

- `project.yml` : paquet Sparkle, clés `SUFeedURL`, `SUPublicEDKey`, `SUEnableInstallerLauncherService`, `SUEnableAutomaticChecks`, exceptions mach-lookup du sandbox.
- `App/CairnApp.swift` : contrôleur Sparkle et commande de menu.
- `scripts/release.sh` : signature du DMG et `appcast.xml` joint à la release.
- Clé privée EdDSA dans le trousseau de la machine de release (à sauvegarder).
