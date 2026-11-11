# Spec Delta

## Purpose

Récupère les nouveaux articles des flux abonnés, au lancement et à la demande, sans créer de doublons et sans qu'un flux défaillant bloque les autres.

## ADDED Requirements

### Requirement: Rafraîchir au lancement
Le système SHALL récupérer tous les flux abonnés au lancement de l'application, sans bloquer l'interface.

#### Scenario: Lancement de l'application
- **WHEN** l'utilisateur lance l'application
- **THEN** les flux sont récupérés et les nouveaux articles apparaissent pendant que l'interface reste utilisable

### Requirement: Rafraîchir à la demande
Le système SHALL permettre de rafraîchir tous les flux via une commande et le raccourci ⌘R. Une indication MUST signaler qu'un rafraîchissement est en cours, et une nouvelle demande pendant un rafraîchissement en cours MUST être ignorée.

#### Scenario: Rafraîchissement manuel
- **WHEN** l'utilisateur appuie sur ⌘R
- **THEN** tous les flux sont récupérés et un indicateur est visible jusqu'à la fin

#### Scenario: Double demande
- **WHEN** l'utilisateur appuie sur ⌘R alors qu'un rafraîchissement est en cours
- **THEN** aucun second rafraîchissement n'est lancé

### Requirement: Extraire les articles
Le système SHALL extraire de chaque flux RSS, Atom ou JSON Feed les articles avec leur titre, lien, date de publication et contenu (ou résumé). Un article sans date MUST recevoir la date de sa première récupération.

#### Scenario: Article sans date
- **WHEN** un flux contient un article sans date de publication
- **THEN** l'article est enregistré avec la date à laquelle il a été récupéré

### Requirement: Dédoublonner les articles
Le système MUST NOT créer deux fois le même article d'un même abonnement. Un article est identifié par son identifiant de flux (guid/id), ou à défaut par son lien. L'état lu, gardé, la note et les tags d'un article déjà connu MUST être préservés.

#### Scenario: Rafraîchissements successifs
- **WHEN** un flux est récupéré deux fois sans nouvel article
- **THEN** le nombre d'articles de cet abonnement est inchangé et leurs états sont conservés

### Requirement: Isoler les erreurs par flux
Le système SHALL continuer à récupérer les autres flux quand l'un d'eux échoue (réseau, format invalide), et MUST signaler l'erreur sur l'abonnement concerné.

#### Scenario: Un flux en erreur
- **WHEN** un flux est injoignable pendant un rafraîchissement
- **THEN** les autres flux sont mis à jour et l'abonnement en erreur affiche un indicateur d'erreur

### Requirement: Ignorer les articles déjà expirés
Le système MUST NOT réimporter un article dont la date de publication dépasse la durée de conservation des articles non gardés.

#### Scenario: Ancien article toujours présent dans le flux
- **WHEN** un flux contient un article publié il y a plus de 30 jours et absent de la base
- **THEN** cet article n'est pas ajouté
