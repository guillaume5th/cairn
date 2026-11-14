# Design

## Context

Cairn est sandboxé et signé ad hoc (pas de compte développeur Apple). `scripts/release.sh` construit l'app de release, en fait un DMG et l'attache à la release GitHub créée par release-please. `CFBundleVersion` est le nombre de commits, donc croissant. Voir proposal.md.

## Goals / Non-Goals

**Goals:** mises à jour vérifiées et installées par l'app, sans service à héberger.

**Non-Goals:** mises à jour delta ; canal bêta ; réglage pour couper la vérification (Sparkle le propose dans sa fenêtre) ; notarisation.

## Decisions

- **Sparkle 2 via Swift Package Manager, `SPUStandardUpdaterController` créé au lancement.** L'interface standard de Sparkle, traduite en français. Commande « Rechercher les mises à jour… » après « À propos de Cairn », désactivée quand une vérification est en cours (`canCheckForUpdates`).
- **Sandbox : service XPC d'installation (`SUEnableInstallerLauncherService`) et exceptions mach-lookup `<bundle id>-spks` / `-spki`.** Pas de service de téléchargement : l'app a déjà `network.client`.
- **Appcast publié comme fichier de la release ; `SUFeedURL` = `https://github.com/guillaume5th/cairn/releases/latest/download/appcast.xml`.** GitHub redirige vers la dernière release : rien à héberger ni à commiter. L'appcast ne contient que la dernière version, ce qui suffit (Sparkle ne propose que la plus récente).
- **Le DMG est signé EdDSA par `sign_update`** ; la clé privée vit dans le trousseau (créée une fois par `generate_keys`), la clé publique dans `project.yml`.
- **Cairn Dev : updater non démarré et commande absente** (`#if DEBUG`).
- **Vérification automatique activée d'office** (`SUEnableAutomaticChecks`) : pas de question au deuxième lancement.

## Risks / Trade-offs

- [App signée ad hoc] → Sparkle valide la mise à jour par sa signature EdDSA ; l'identité de signature change à chaque build, ce que Sparkle admet quand la clé EdDSA est la même. À confirmer sur la première vraie mise à jour.
- [Perte de la clé privée] → plus aucune mise à jour ne serait acceptée par les apps installées ; l'exporter (`generate_keys -x`) et la ranger en lieu sûr.
- [Dépôt privé] → l'appcast et le DMG seraient inaccessibles ; le dépôt doit être public.
- [La version installée aujourd'hui n'a pas Sparkle] → la première version avec Sparkle s'installe encore à la main.
