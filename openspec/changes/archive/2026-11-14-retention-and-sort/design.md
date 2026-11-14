# Design

## Context

`Retention.days` (30) dans `CairnCore` fixe la purge (`Library.purge`, au lancement) et l'âge maximal à l'import (`Library.ingest`). La liste affichée (`ContentView.visibleArticles`) suit l'ordre des requêtes : publication décroissante, ou date de garde décroissante pour un cairn. Voir proposal.md.

## Goals / Non-Goals

**Goals:** deux réglages simples, sans toucher aux signatures de `Library`.

**Non-Goals:** « Ne jamais purger » (la base grossirait sans fin) ; tri par source ou par titre ; ordre propre à chaque vue.

## Decisions

- **`Retention.days` lit `UserDefaults` (clé `articleRetentionDays`, 30 par défaut).** `ingest` et `purge` l'utilisent déjà : rien d'autre ne change, et les tests gardent 30 jours. Alternative écartée : passer la durée en paramètre de `refreshAll`, `ingest` et `purge`, plus de diff pour le même résultat.
- **Réglages : `Picker` « Conserver les articles non gardés »** dans la section Abonnements (valeurs 7, 14, 30, 60, 90, 180, 365). Le pied de section rappelle que les articles gardés ne sont jamais supprimés.
- **Ordre : clé `oldestFirst`**, `Picker` dans le menu Présentation ; `visibleArticles` est inversé quand elle est vraie, ce qui couvre les cairns (date de garde) comme les flux (date de publication). Le prochain non lu suit l'ordre affiché.
- **Sauvegarde :** les deux clés rejoignent `BackupSettings.settingKeys`.

## Risks / Trade-offs

- [Raccourcir la durée supprime des articles au lancement suivant, sans confirmation] → c'est le rôle du réglage ; le pied de section le dit.
