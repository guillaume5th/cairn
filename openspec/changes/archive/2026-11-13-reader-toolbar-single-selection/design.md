# Design

## Context

Le volet de lecture avait trois barres d'outils écrites séparément : celle d'un article (`ArticleDetailView`), celle d'une sélection (`ArticleSelectionView`) et celle d'un volet vide (`DisabledReaderToolbar`). Ajouter un bouton à l'une sans les autres faisait changer la disposition de la barre. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Une seule définition des boutons du lecteur, dans le même ordre pour les trois états.

**Non-Goals:**
- Changer l'ordre ou les icônes des boutons.

## Decisions

- **`ReaderToolbar<Reading>`, générique sur les boutons de lecture.** Article complet et Résumer dépendent de l'état d'un seul article (chargement en cours, résumé existant) : `ArticleDetailView` les passe en `@ViewBuilder`. Pour une sélection ou un volet vide, une initialisation sans ce paramètre met `DisabledReadingButtons` (les deux boutons grisés). `ReaderToolbar.empty` remplace `DisabledReaderToolbar`.
- **Une seule logique pour Marquer, quel que soit le nombre d'articles** : « lu » si au moins un est non lu, sinon « non lu ». Pour un article seul, c'est ce qui fait basculer le bouton. Alternative écartée : garder un cas particulier « toujours non lu » pour un article seul, qui ne permettait pas de le remettre en lu.
- **Partager suit le nombre d'articles** : `ShareButton` pour un article, bouton grisé sinon. Un seul article coché en mode sélection a donc Partager actif. Alternative écartée : un paramètre pour griser Partager en mode sélection, qui aurait gardé une exception sans utilité.
- **Ouvrir dans le navigateur passe par `OpenInBrowser.open`** dans les trois cas, grisé quand aucun article n'a de lien web. Les confirmations (`unkeepConfirmation`, `openConfirmation`) restent portées par chaque volet, une barre d'outils ne pouvant pas les présenter.

## Risks / Trade-offs

- [Le bouton Marquer d'un article seul change d'icône après un clic] → c'est le comportement de Mail, et l'infobulle indique l'action.
- [Pas de test automatisé de l'interface] → vérification manuelle dans l'app, voir tasks.md.
