# Proposal

## Why

Les articles non gardés sont supprimés au bout de 30 jours, sans réglage : trop court pour qui lit par à-coups, trop long pour qui suit des flux très actifs. Et la liste est toujours triée du plus récent au plus ancien, alors que certains préfèrent lire dans l'ordre de publication.

## What Changes

- Réglage « Conserver les articles non gardés » dans la section Abonnements : 7, 14 ou 30 jours, 2, 3 ou 6 mois, 1 an ; 30 jours par défaut (comportement actuel). Il fixe la purge au lancement et l'âge au-delà duquel un article du flux n'est pas importé.
- « Ordre des articles » dans le menu Présentation : « Plus récents d'abord » (par défaut) ou « Plus anciens d'abord », pour toutes les listes d'articles, conservé entre les lancements.
- Les deux réglages font partie de la sauvegarde.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `article-reading` : durée de purge réglable ; ordre de la liste.
- `feed-fetching` : l'âge maximal d'import suit le réglage.

## Impact

- `CairnCore` : `Retention.days` lu dans les préférences (clé `articleRetentionDays`, 30 par défaut).
- `App/DigestViews.swift` (Réglages), `App/CairnApp.swift` (menu), `App/ContentView.swift` (ordre), `App/Backups.swift` (clés sauvegardées).
