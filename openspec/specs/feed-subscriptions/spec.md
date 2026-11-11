# feed-subscriptions Specification

## Purpose

Permet à l'utilisateur de choisir les sources de sa veille : s'abonner à des flux RSS/Atom, les gérer, et les échanger avec d'autres lecteurs via OPML.

## Requirements

### Requirement: Ajouter un abonnement par URL
Le système SHALL permettre d'ajouter un abonnement à partir de l'URL d'un flux RSS ou Atom. Le système MUST vérifier que l'URL renvoie un flux lisible avant d'enregistrer l'abonnement, et utiliser le titre du flux comme nom de l'abonnement.

#### Scenario: Flux valide
- **WHEN** l'utilisateur saisit l'URL d'un flux RSS ou Atom valide
- **THEN** l'abonnement est enregistré avec le titre du flux et ses articles apparaissent

#### Scenario: URL invalide ou injoignable
- **WHEN** l'utilisateur saisit une URL qui ne renvoie pas un flux lisible
- **THEN** aucun abonnement n'est créé et un message d'erreur explique le problème

#### Scenario: Flux déjà suivi
- **WHEN** l'utilisateur saisit l'URL d'un flux auquel il est déjà abonné
- **THEN** aucun doublon n'est créé et l'utilisateur en est informé

### Requirement: Lister les abonnements
Le système SHALL afficher la liste des abonnements avec, pour chacun, son nom et le nombre d'articles non lus.

#### Scenario: Affichage de la liste
- **WHEN** l'utilisateur ouvre l'application avec au moins un abonnement
- **THEN** chaque abonnement apparaît avec son nom et son nombre d'articles non lus

### Requirement: Supprimer un abonnement
Le système SHALL permettre de supprimer un abonnement. Ses articles non gardés MUST être supprimés ; ses articles gardés dans le cairn MUST être conservés.

#### Scenario: Suppression avec articles gardés
- **WHEN** l'utilisateur supprime un abonnement dont un article est gardé
- **THEN** l'abonnement et ses articles non gardés disparaissent, l'article gardé reste dans le cairn

### Requirement: Importer un fichier OPML
Le système SHALL permettre d'importer un fichier OPML et de créer un abonnement pour chaque flux qu'il contient, y compris les flux imbriqués dans des dossiers. Les dossiers MUST être ignorés (import à plat) et les flux déjà suivis MUST être ignorés.

#### Scenario: Import d'un OPML avec dossiers
- **WHEN** l'utilisateur importe un OPML contenant des flux répartis dans des dossiers
- **THEN** un abonnement est créé pour chaque flux, sans structure de dossiers

#### Scenario: Réimport du même fichier
- **WHEN** l'utilisateur importe un OPML dont tous les flux sont déjà suivis
- **THEN** aucun abonnement n'est ajouté et l'utilisateur voit le nombre de flux ignorés

#### Scenario: Fichier OPML illisible
- **WHEN** l'utilisateur importe un fichier qui n'est pas un OPML valide
- **THEN** aucun abonnement n'est créé et un message d'erreur est affiché

### Requirement: Exporter les abonnements en OPML
Le système SHALL permettre d'exporter tous les abonnements dans un fichier OPML 2.0 que l'utilisateur enregistre où il le souhaite. Chaque flux MUST y figurer avec son nom et son URL.

#### Scenario: Export puis réimport
- **WHEN** l'utilisateur exporte ses abonnements puis réimporte le fichier dans une base vide
- **THEN** les mêmes abonnements sont recréés
