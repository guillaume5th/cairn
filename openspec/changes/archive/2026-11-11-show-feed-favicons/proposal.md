# Proposal

## Why

Dans la barre latérale, la liste d'articles et le panneau de lecture, les sources ne se distinguent que par leur nom en texte. Avec une vingtaine d'abonnements, repérer d'un coup d'œil d'où vient un article est lent. L'icône du site (favicon) est le repère visuel que tous les lecteurs de flux utilisent pour ça.

## What Changes

- Récupérer l'icône du site de chaque abonnement, la meilleure disponible : celle déclarée par le flux si elle existe, sinon la plus grande déclarée par la page d'accueil du site, sinon `/apple-touch-icon.png` puis `/favicon.ico`. Une icône quasi transparente est ignorée.
- Conserver l'icône localement avec l'abonnement, pour qu'elle s'affiche hors ligne et sans retélécharger à chaque lancement. La revérifier périodiquement.
- Afficher l'icône dans un cercle Liquid Glass, avec une marge : devant le nom de l'abonnement dans la barre latérale, à gauche de chaque ligne de la liste d'articles (même taille sur toutes les lignes), et devant la source dans l'en-tête de l'article affiché.
- Afficher une icône générique quand un abonnement n'a pas d'icône (pas encore récupérée, introuvable ou illisible).
- Un article gardé dont l'abonnement est supprimé conserve l'icône de sa source, comme il conserve déjà son nom.

## Capabilities

### New Capabilities
- `feed-icons` : récupération, conservation et affichage de l'icône du site de chaque abonnement, avec icône générique de repli.

### Modified Capabilities
<!-- Aucune : les exigences existantes (lister les abonnements, lister et afficher les articles, garder un article) restent vraies ; l'icône s'ajoute sans en changer le comportement. -->

## Impact

- **Données** : deux nouvelles propriétés optionnelles sur l'abonnement (icône et date de dernière vérification) et une sur l'article (icône de la source conservée). Migration SwiftData légère automatique, schéma toujours compatible CloudKit.
- **Réseau** : jusqu'à deux requêtes supplémentaires par abonnement (page d'accueil, icône) lors de la vérification, pas à chaque rafraîchissement.
- **Code** : `CairnCore` (lecture des champs d'icône du flux, recherche et téléchargement de l'icône, conservation à la suppression d'un abonnement) ; `App` (barre latérale, ligne d'article, en-tête de l'article).
- **Dépendances** : aucune nouvelle.
