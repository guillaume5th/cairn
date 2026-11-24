# Proposal

## Why

Avec plusieurs cairns (« Pro », « Lectures », « Recettes »…), tous portent le même symbole dans la barre latérale et la même marque « gardé » dans la liste d'articles : on ne voit pas dans quel cairn est un article sans l'ouvrir. Une couleur par cairn, comme les étiquettes du Finder, rend ce classement visible d'un coup d'œil.

## What Changes

- Chaque cairn peut recevoir une couleur parmi une palette fixe : rouge, orange, jaune, vert, bleu, violet, gris. Par défaut, il n'en a pas et garde la couleur d'accent, comme aujourd'hui.
- La couleur se choisit dans le menu contextuel du cairn de la barre latérale (sous-menu « Couleur », avec « Aucune »).
- Le symbole du cairn dans la barre latérale et la marque « gardé » d'une ligne d'article prennent la couleur du cairn de l'article. Sur une ligne sélectionnée, la marque reste blanche.
- La couleur est synchronisée avec iCloud comme le reste du cairn, et incluse dans la sauvegarde ; une sauvegarde plus ancienne se restaure avec des cairns sans couleur.

## Capabilities

### New Capabilities

### Modified Capabilities
- `cairn`: ajout d'une exigence « Couleur d'un cairn ».
- `backup`: « Contenu de la sauvegarde » inclut la couleur des cairns.

## Impact

- `CairnCore/Sources/CairnCore/Models.swift` : attribut optionnel sur `Cairn` (compatible CloudKit, aucune migration). Une énumération des couleurs de la palette dans CairnCore.
- `CairnCore/Sources/CairnCore/Backup.swift` : champ optionnel des couleurs, sans changer la version du format.
- `App/SidebarView.swift` (menu contextuel, symbole), `App/ContentView.swift` (`KeptMark`), `App/Localizable.xcstrings` (noms des couleurs).
- Tests CairnCore de la sauvegarde.
- Hors périmètre : emoji, couleur libre (sélecteur de couleur), couleur des tags, couleur dans l'export Markdown et dans Spotlight.
