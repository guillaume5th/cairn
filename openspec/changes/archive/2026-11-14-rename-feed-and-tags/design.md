# Design

## Context

Le titre d'un abonnement est fixé à l'ajout (`Library.addFeed`) ; `ingest` ne le touche plus, et chaque article en copie le titre dans `sourceTitle`. Les tags sont globaux (`Tag.key` insensible à la casse et aux accents), affichés sous chaque cairn qui en porte. La barre latérale a déjà une alerte de nom (`Naming`) pour les dossiers et les cairns. Voir proposal.md.

## Goals / Non-Goals

**Goals:** réutiliser l'alerte de nom et les règles de nom existantes.

**Non-Goals:** revenir au titre d'origine du flux (effacer le champ suffit à le refuser ; l'utilisateur peut retaper un titre) ; renommer plusieurs abonnements à la fois ; tag limité à un seul cairn.

## Decisions

- **`Library.rename(_ feed:to:)`** : titre rogné, vide refusé (`CairnError.emptyFeedName`), recopié dans `sourceTitle` des articles de l'abonnement pour que les lignes suivent.
- **`Library.rename(_ tag:to:context:) -> Tag`** : nom vide refusé (`emptyTagName`). Si un autre tag a la même clé, les articles du tag renommé reçoivent l'autre tag, puis le tag renommé est supprimé : c'est la fusion ; la fonction renvoie le tag qui reste, pour mettre à jour la sélection.
- **`Library.delete(_ tag:context:)`** : `context.delete`, la relation se vide d'elle-même (`nullify`).
- **Barre latérale** : `Naming` gagne `.feed` et `.tag` ; « Renommer… » dans le menu d'un seul abonnement et d'un tag. L'alerte d'un tag précise que le renommage vaut pour tous les cairns et qu'un nom existant fusionne. Si le tag sélectionné est renommé, la sélection suit sa nouvelle clé ; s'il est supprimé, elle revient à « Tous les articles ».

## Risks / Trade-offs

- [Fusion irréversible] → annoncée dans l'alerte de nom ; pas d'annulation, comme le renommage d'un dossier.
