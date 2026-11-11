# Proposal

## Why

Faire sa veille tech au quotidien implique aujourd'hui de jongler entre onglets, lecteurs RSS génériques et notes éparpillées : on lit beaucoup, on garde peu, et ce qu'on garde est difficile à retrouver. Cairn réunit les sources, permet de survoler rapidement les nouveautés et de conserver uniquement les « pierres » qui valent la peine, annotées et retrouvables. Le repo est vierge : cette première version pose l'application macOS complète.

## What Changes

- Création d'une application macOS native (première plateforme ; iOS/iPadOS visés ensuite).
- Abonnement à des flux RSS / Atom (ajout par URL, suppression, liste), import et export OPML.
- Récupération des flux au lancement et à la demande, avec dédoublonnage des articles.
- Lecture : liste des articles, état lu / non lu, affichage du contenu fourni par le flux, ouverture de l'article dans le navigateur.
- Purge automatique des articles non gardés après 30 jours.
- Le « cairn » : garder un article, lui ajouter une note personnelle et des tags, retrouver les articles gardés par recherche plein texte.
- Hors périmètre V1 : agrégateurs (HN, Reddit), newsletters e-mail, réseaux sociaux, WebView ou mode lecture extrait, rafraîchissement en arrière-plan, synchronisation iCloud, fonctionnalités IA, application iOS.

## Capabilities

### New Capabilities

- `feed-subscriptions`: gestion des abonnements aux flux RSS/Atom, y compris import et export OPML.
- `feed-fetching`: récupération des flux abonnés, extraction des articles et dédoublonnage.
- `article-reading`: consultation des articles reçus, état lu/non lu, ouverture dans le navigateur et purge des articles anciens non gardés.
- `cairn`: conservation des articles choisis avec note, tags et recherche plein texte.

### Modified Capabilities

<!-- Aucune : le projet n'a pas encore de spec. -->

## Impact

- Nouveau code : application SwiftUI macOS et module cœur testable (aucun code existant).
- Nouvelle dépendance : FeedKit (parsing RSS/Atom/JSON Feed) via Swift Package Manager.
- Outillage : Xcode est requis pour construire et lancer l'application (absent de la machine à ce jour) ; XcodeGen pour générer le projet.
- Données stockées localement sur le Mac ; aucun service distant.
