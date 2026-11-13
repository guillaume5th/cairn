# Tasks

## 1. Format et logique (CairnCore)

- [x] 1.1 Ajouter `CairnCore/Sources/CairnCore/Backup.swift` : structures `Codable` versionnées (abonnements, dossiers, cairns, articles gardés, réglages en valeurs JSON simples)
- [x] 1.2 Ajouter `Library.makeBackup(context:settings:)` (abonnements, dossiers, cairns, articles gardés seulement)
- [x] 1.3 Ajouter `Library.restore(_:context:)` : décode et valide avant toute suppression, supprime articles, abonnements, dossiers, étiquettes et cairns (pas les résumés quotidiens), recrée tout, puis `ensureCairn`
- [x] 1.4 Tests dans `BackupTests` : aller-retour complet (dossiers, option articles complets, cairn, note, étiquettes, résumé), articles non gardés exclus, restauration qui remplace un abonnement absent, fichier illisible ou version inconnue sans effet, pas de doublon après ingestion d'un article gardé restauré ; `swift test` vert

## 2. Écriture dans le dossier (App)

- [x] 2.1 Ajouter le droit `com.apple.security.files.bookmarks.app-scope` (dans `project.yml`, qui génère `App/Cairn.entitlements`)
- [x] 2.2 Ajouter le choix du dossier (`fileImporter` sur `.folder`), le signet de sécurité dans `UserDefaults`, sa résolution (signet périmé recréé, illisible signalé)
- [x] 2.3 Écrire la sauvegarde `Cairn <aaaa-MM-jj HHmm>.json` de façon atomique, puis supprimer les `Cairn ….json` au-delà des 7 plus récents ; vérifier dans Cairn Dev avec un dossier contenant un autre fichier
- [x] 2.4 Planifier : au lancement après le premier rafraîchissement et dans une boucle d'une minute, si dossier choisi et dernière sauvegarde de plus de 24 h ; après un échec, attendre une heure ; vérifier en reculant `backupLastDate` dans Cairn Dev

## 3. Réglages et restauration

- [x] 3.1 Ajouter la section « Sauvegarde » : dossier et « Choisir… », date de la dernière sauvegarde ou erreur, « Sauvegarder maintenant » ; vérifier sur capture
- [x] 3.2 Ajouter « Restaurer… » : choix du fichier, confirmation destructive, restauration, sauvegarde du contexte, rafraîchissement ; vérifier dans Cairn Dev qu'après suppression d'un abonnement et d'un cairn, la restauration les ramène avec les réglages
- [x] 3.3 Vérifier qu'un signet enregistré par un build se résout encore après un nouveau build de Cairn Dev ; sinon, noter le comportement constaté dans design.md

## 4. Tous les articles et icônes

- [x] 4.1 Sauvegarder tous les articles (gardés ou non, avec `isKept`, cairn optionnel, `sourceIconData`) et l'icône des abonnements (`iconData`, `iconCheckedAt`) ; les restaurer
- [x] 4.2 Tests : état lu d'un article non gardé restauré, icône d'abonnement restaurée, pas de doublon au rafraîchissement pour un article non gardé restauré ; `swift test` vert
- [x] 4.3 Vérifier dans Cairn Dev qu'après restauration les articles non gardés retrouvent leur état lu et l'abonnement son icône

## 5. Intégration

- [x] 5.1 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`
