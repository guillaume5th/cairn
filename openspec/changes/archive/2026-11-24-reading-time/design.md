# Design

## Context

La ligne de la liste est dans `ContentView` (source, puis date relative à droite) ; l'en-tête est dans `ArticleDetailView`. `Library.readableContent` donne déjà le texte intégral ou, à défaut, celui du flux. Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Un calcul pur dans CairnCore, testable, assez léger pour être appelé à chaque rendu de ligne.

**Non-Goals:**
- Vitesse de lecture réglable, mise en cache, estimation propre aux écritures sans espaces.

## Decisions

- **Source du texte** : `Library.readableContent`, comme les résumés, donc le temps suit le texte intégral quand il est chargé.
- **Comptage en un passage** : `Library.readingMinutes` parcourt les octets UTF-8 du HTML, ignore ce qui est entre `<` et `>` et compte les débuts de mot, sans allocation. Alternative écartée : `plainText(...)` (regex et seize remplacements d'entités sur le HTML entier), essayée d'abord et qui a rendu l'app très lente, la liste le rappelant pour chaque ligne à chaque rendu.
- **230 mots par minute**, arrondi à la minute la plus proche, au moins 1 ; `nil` sans mot, pour ne rien afficher.
- **Placement dans la liste** : à gauche, après la source, avec l'icône `timer` (2 pt d'écart), et la date relative seule à droite : à droite, les deux nombres (« 14 min » et « 1 hour ago ») se confondaient. La durée a une priorité d'affichage plus haute que la source, qui est tronquée en premier.
- **En-tête** : suffixe du texte « source · date », libellé `"%lld min read"` dans `Localizable.xcstrings`.

## Risks / Trade-offs

- [Une entité comme `&nbsp;` compte comme partie d'un mot] → écart négligeable à l'échelle de la minute, noté en commentaire (`shortcut:`).
- [Le calcul se refait à chaque rendu de ligne] → un passage linéaire sans allocation ; à mettre en cache sur l'article si la liste ralentit de nouveau.
- [Écritures sans espaces] → un article en chinois ou en japonais est très sous-estimé ; hors périmètre.
