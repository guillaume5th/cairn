# Spec Delta

## Purpose

Permet de survoler rapidement les articles reçus, de les lire avec le contenu fourni par le flux ou dans le navigateur, et laisse s'effacer ce qui n'a pas été gardé.

## ADDED Requirements

### Requirement: Lister les articles
Le système SHALL afficher les articles de l'abonnement sélectionné, ou de tous les abonnements via une vue « Tous les articles », du plus récent au plus ancien. Chaque article MUST montrer son titre, sa source, sa date et s'il est lu ou non.

#### Scenario: Vue de tous les articles
- **WHEN** l'utilisateur sélectionne « Tous les articles »
- **THEN** les articles de tous les abonnements sont listés du plus récent au plus ancien

#### Scenario: Vue d'un abonnement
- **WHEN** l'utilisateur sélectionne un abonnement
- **THEN** seuls les articles de cet abonnement sont listés

### Requirement: Filtrer les non lus
Le système SHALL permettre de n'afficher que les articles non lus dans la liste courante.

#### Scenario: Filtre activé
- **WHEN** l'utilisateur active le filtre « Non lus »
- **THEN** seuls les articles non lus de la liste courante sont affichés

### Requirement: Afficher un article
Le système SHALL afficher le titre, la source, la date et le contenu fourni par le flux de l'article sélectionné, mis en forme (HTML rendu). Le contenu MUST être affiché sans exécuter de script ni charger de contenu distant autre que les images.

#### Scenario: Sélection d'un article
- **WHEN** l'utilisateur sélectionne un article
- **THEN** son contenu s'affiche dans le panneau de lecture

#### Scenario: Article sans contenu
- **WHEN** l'article sélectionné n'a ni contenu ni résumé dans le flux
- **THEN** le panneau indique qu'aucun contenu n'est disponible et propose de l'ouvrir dans le navigateur

### Requirement: État lu / non lu
Le système SHALL marquer un article comme lu quand il est affiché, et MUST permettre de le remettre manuellement en non lu ou de marquer tous les articles de la liste courante comme lus.

#### Scenario: Lecture d'un article
- **WHEN** l'utilisateur affiche un article non lu
- **THEN** l'article est marqué lu et le compteur de non lus de son abonnement diminue

#### Scenario: Tout marquer comme lu
- **WHEN** l'utilisateur choisit « Tout marquer comme lu » sur la liste courante
- **THEN** tous les articles de cette liste deviennent lus

### Requirement: Ouvrir dans le navigateur
Le système SHALL permettre d'ouvrir le lien de l'article dans le navigateur par défaut.

#### Scenario: Ouverture
- **WHEN** l'utilisateur demande à ouvrir l'article dans le navigateur
- **THEN** le navigateur par défaut s'ouvre sur le lien de l'article

### Requirement: Purger les articles non gardés
Le système SHALL supprimer automatiquement les articles non gardés dont la date de publication remonte à plus de 30 jours. Les articles gardés MUST NOT être purgés.

#### Scenario: Article ancien non gardé
- **WHEN** l'application démarre et qu'un article non gardé a plus de 30 jours
- **THEN** cet article est supprimé

#### Scenario: Article ancien gardé
- **WHEN** l'application démarre et qu'un article gardé a plus de 30 jours
- **THEN** cet article est conservé
