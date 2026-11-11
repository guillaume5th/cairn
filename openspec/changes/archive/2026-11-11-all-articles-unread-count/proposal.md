# Proposal

## Why

La barre latérale montre le nombre d'articles non lus de chaque abonnement, mais pas le total. Pour savoir s'il reste quelque chose à lire, il faut parcourir les compteurs un par un ou ouvrir « Tous les articles ».

## What Changes

- L'entrée « Tous les articles » de la barre latérale affiche le nombre d'articles non lus de sa liste, comme les abonnements.
- Ce nombre compte tous les articles non lus de la liste, y compris les articles gardés dont l'abonnement a été supprimé. Il peut donc dépasser la somme des compteurs des abonnements.
- Le filtre « Non lus » ne change pas le compteur.
- Aucun compteur n'est ajouté sur « Cairn » ni sur les tags.

## Capabilities

### New Capabilities
<!-- Aucune. -->

### Modified Capabilities
- `article-reading` : ajout d'une exigence sur le compteur de non lus de « Tous les articles ». L'exigence « Lister les abonnements » de `feed-subscriptions` est inchangée.

## Impact

- **Code** : `App/SidebarView.swift` (compteur sur l'entrée « Tous les articles »).
- **Données** : aucune modification du modèle.
- **Dépendances** : aucune nouvelle.
