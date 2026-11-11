# Spec Delta

## Purpose

Le cairn conserve durablement les articles que l'utilisateur juge dignes d'être retenus, avec ses propres notes et tags, et permet de les retrouver par recherche.

## ADDED Requirements

### Requirement: Garder un article
Le système SHALL permettre de garder un article et de ne plus le garder. Un article gardé MUST rester disponible même si son abonnement est supprimé ou s'il disparaît du flux.

#### Scenario: Garder un article
- **WHEN** l'utilisateur garde un article
- **THEN** l'article apparaît dans la vue Cairn

#### Scenario: Ne plus garder
- **WHEN** l'utilisateur retire un article du cairn
- **THEN** l'article disparaît de la vue Cairn et redevient soumis à la purge

### Requirement: Supprimer un article orphelin
Le système SHALL permettre de supprimer manuellement, après confirmation, un article dont l'abonnement a été supprimé, qu'il soit gardé ou non. Un article d'un abonnement suivi MUST NOT être supprimable manuellement, car le prochain rafraîchissement le recréerait.

#### Scenario: Suppression d'un article orphelin
- **WHEN** l'utilisateur supprime un article dont l'abonnement a été supprimé et confirme
- **THEN** l'article disparaît définitivement, avec sa note et ses tags

#### Scenario: Article d'un abonnement suivi
- **WHEN** l'utilisateur affiche le menu contextuel d'un article d'un abonnement suivi
- **THEN** aucune action de suppression n'est proposée

### Requirement: Vue Cairn
Le système SHALL proposer une vue Cairn listant tous les articles gardés, du plus récemment gardé au plus ancien.

#### Scenario: Consultation du cairn
- **WHEN** l'utilisateur ouvre la vue Cairn
- **THEN** les articles gardés sont listés du plus récemment gardé au plus ancien

### Requirement: Note personnelle
Le système SHALL permettre d'écrire et modifier une note texte libre sur un article gardé. La note MUST être enregistrée sans action explicite de sauvegarde.

#### Scenario: Saisie d'une note
- **WHEN** l'utilisateur écrit une note sur un article gardé puis relance l'application
- **THEN** la note est toujours présente

#### Scenario: Retrait d'un article annoté
- **WHEN** l'utilisateur retire du cairn un article qui a une note
- **THEN** une confirmation lui est demandée avant de perdre la note

### Requirement: Tags
Le système SHALL permettre d'ajouter et retirer des tags sur un article gardé, en réutilisant les tags existants. Les tags MUST être insensibles à la casse (« Swift » et « swift » sont le même tag).

#### Scenario: Ajout d'un tag existant
- **WHEN** l'utilisateur tape le début d'un tag déjà utilisé
- **THEN** le tag existant est proposé

#### Scenario: Filtrer par tag
- **WHEN** l'utilisateur sélectionne un tag dans la vue Cairn
- **THEN** seuls les articles gardés portant ce tag sont affichés

### Requirement: Recherche dans le cairn
Le système SHALL permettre de rechercher parmi les articles gardés un texte présent dans le titre, le contenu, la note ou les tags, sans tenir compte de la casse ni des accents.

#### Scenario: Recherche dans une note
- **WHEN** l'utilisateur recherche un mot qui n'apparaît que dans la note d'un article gardé
- **THEN** cet article figure dans les résultats

#### Scenario: Recherche sans accent
- **WHEN** l'utilisateur recherche « deploiement » et qu'un article gardé contient « Déploiement »
- **THEN** cet article figure dans les résultats
