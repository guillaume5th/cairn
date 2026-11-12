# Proposal

## Why

Pour s'abonner, il faut aujourd'hui connaître l'URL exacte du flux (`…/feed.xml`, `…/rss`…), que la plupart des sites n'affichent pas. On connaît en général l'adresse du site, pas celle de son flux. Cairn doit trouver le flux tout seul à partir de l'adresse du site.

## What Changes

- Le champ « Ajouter un abonnement » accepte l'adresse d'un site (ou d'une page) aussi bien que celle d'un flux.
- Si l'adresse n'est pas un flux, Cairn cherche les flux déclarés par la page (balises `<link rel="alternate">` RSS, Atom ou JSON Feed), puis, à défaut, quelques emplacements usuels du site (`/feed`, `/rss`, `/atom.xml`…).
- Un seul flux trouvé : l'abonnement est créé directement. Plusieurs : l'utilisateur choisit dans une liste (titre et adresse de chaque flux). Aucun : un message l'indique.
- Une adresse saisie sans `https://` (« exemple.com ») est complétée.
- Mac, iPhone et iPad.

## Capabilities

### New Capabilities

_Aucune._

### Modified Capabilities

- `feed-subscriptions` : l'ajout par URL accepte une adresse de site et découvre son flux, avec choix entre plusieurs flux.

## Impact

- CairnCore : `Library.addFeed` (normalisation, découverte), nouvel analyseur de liens HTML partagé avec `FeedIcon.declaredIcons`, `CairnError` (aucun flux trouvé).
- App : `AppState.addFeed` et la confirmation de choix entre plusieurs flux dans `ContentView`.
- Aucune dépendance nouvelle, aucun changement de données.
