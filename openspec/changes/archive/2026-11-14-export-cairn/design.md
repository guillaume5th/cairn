# Design

## Context

L'export OPML passe par `Library.exportOPML` (données) et `OPMLDocument` + `fileExporter` (app). Les articles d'un cairn sont affichés par date de garde décroissante. Voir proposal.md.

## Goals / Non-Goals

**Goals:** un fichier Markdown lisible tel quel, produit par `CairnCore` pour être testé.

**Non-Goals:** export HTML ou PDF ; contenu complet des articles ; export d'un tag seul ou de plusieurs cairns à la fois ; réimport.

## Decisions

- **`Library.markdown(for:now:)` renvoie une `String`.** Dates en français (`fr_FR`), comme l'interface. Crochets du titre échappés pour ne pas casser le lien.
- **`OPMLDocument` devient `ExportDocument`, qui accepte OPML et Markdown.** Un seul type de document pour les deux exports ; le `contentType` du `fileExporter` choisit l'extension. Alternative écartée : un second type de document identique.

## Risks / Trade-offs

- [Un titre ou une note contenant du Markdown est interprété par le lecteur] → acceptable : c'est du texte de l'utilisateur ou du flux, lisible même mal rendu.
