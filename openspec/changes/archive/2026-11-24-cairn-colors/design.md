# Design

## Context

`Cairn` (`CairnCore/Models.swift`) est un modèle SwiftData synchronisé par CloudKit : chaque propriété a une valeur par défaut ou est optionnelle. La barre latérale (`SidebarView`) affiche chaque cairn avec `Label(cairn.name, image: "cairn")` et un menu contextuel (Renommer…, Supprimer le cairn…). La ligne d'article affiche `KeptMark`, le symbole `cairn.fill` en couleur d'accent, blanc sur une ligne sélectionnée (`backgroundProminence`). La sauvegarde (`Backup`, version 1) liste les cairns par nom (`cairns: [String]`) et a déjà ajouté un champ optionnel sans changer de version (`notifiesNewArticles`). Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Une couleur par cairn, synchronisée, sauvegardée, visible dans la barre latérale et sur les lignes.
- Aucune migration de données, aucune nouvelle version du format de sauvegarde.

**Non-Goals:**
- Emoji, couleur libre, couleur des tags, couleur dans l'export Markdown et Spotlight.

## Decisions

- **Stockage** : `public var color: String?` sur `Cairn`, nil par défaut (aucune couleur). Une énumération `CairnColor: String, CaseIterable` dans CairnCore (`red`, `orange`, `yellow`, `green`, `blue`, `purple`, `gray`) donne la palette ; `Cairn.cairnColor` lit `color` via `CairnColor(rawValue:)`, donc une valeur inconnue (écrite par une version future) vaut « aucune ». Alternative écartée : stocker des composantes RVB, qui ne s'adaptent pas au mode sombre et ouvrent la porte à une couleur libre hors périmètre.
- **Rendu** : dans l'app, une extension `CairnColor.color` vers les couleurs système SwiftUI (`.red`, `.orange`…), qui s'adaptent au mode sombre et au contraste augmenté ; sans couleur, `.tint` comme aujourd'hui.
- **Barre latérale** : `Label { Text(cairn.name) } icon: { Image("cairn").foregroundStyle(...) }` pour teinter le seul symbole.
- **Symbole sélectionné** : comme la marque « gardé », le symbole du cairn passe en blanc quand la ligne de la barre latérale est sélectionnée (`backgroundProminence`), sans quoi un cairn bleu disparaît sur la surbrillance bleue.
- **Pastilles du menu** : les menus macOS dessinent les symboles SF en une seule couleur ; chaque pastille est donc une image non-modèle (`NSImage`, `isTemplate = false`) qui garde sa couleur.
- **Marque « gardé »** : `KeptMark` reçoit la couleur du cairn de l'article (`article.cairn?.cairnColor`) ; sur une ligne sélectionnée, le blanc reste prioritaire.
- **Menu** : sous-menu « Couleur » dans le menu contextuel d'un cairn seul, un `Picker` en ligne (« Aucune » puis les sept couleurs, chacune avec une pastille), entre « Renommer… » et « Supprimer le cairn… ».
- **Sauvegarde** : champ optionnel `cairnColors: [String: String]?` (nom du cairn → couleur), écrit seulement pour les cairns colorés ; absent des anciennes sauvegardes, il se décode à nil. La restauration applique la couleur au cairn de ce nom. La version du format reste 1, comme pour `notifiesNewArticles`.

## Risks / Trade-offs

- [Le jaune est peu lisible sur fond clair] → couleur système, qui l'assombrit déjà un peu ; même palette que le Finder, accepté.
- [Une sauvegarde écrite par cette version restaurée par une version plus ancienne] → le champ inconnu est ignoré au décodage, les cairns reviennent sans couleur.
- [Deux Macs, l'un pas encore mis à jour] → l'attribut CloudKit est ignoré par l'ancienne version, qui ne l'efface pas.
