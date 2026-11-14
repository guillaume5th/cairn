# Proposal

## Why

Ce qu'on garde dans un cairn (liens, notes, tags) reste enfermé dans Cairn. Un export Markdown permet de le relire, le partager ou le verser dans un outil de notes (Obsidian, Notes, un dépôt).

## What Changes

- « Exporter en Markdown… » dans le menu contextuel d'un cairn : un fichier `.md` nommé d'après le cairn, enregistré où l'utilisateur veut.
- Le fichier contient le nom du cairn, puis chaque article (du plus récemment gardé au plus ancien) : titre en lien, source, dates de publication et de garde, tags, note en citation.
- Pas de contenu des articles ni de résumé IA : l'export garde ce que l'utilisateur a ajouté et le lien vers l'original.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `cairn` : export Markdown d'un cairn.

## Impact

- `CairnCore` : `Library.markdown(for:)`, testé.
- `App/SidebarView.swift` (menu et panneau d'enregistrement), `App/AppState.swift` (`OPMLDocument` devient `ExportDocument`, OPML ou Markdown).
