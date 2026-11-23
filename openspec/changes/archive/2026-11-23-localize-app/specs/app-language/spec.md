# Spec Delta

## Purpose

Afficher Cairn dans la langue du système : en français quand macOS est en français, en anglais dans tous les autres cas.

## ADDED Requirements

### Requirement: Langue de l'interface selon le système
Le système SHALL afficher tous les textes de l'interface (menus, boutons, aides, alertes, réglages, notifications, messages d'erreur, export Markdown) en français lorsque le français est la première langue préférée du système parmi celles que l'app prend en charge, et en anglais sinon. L'app MUST NOT proposer son propre réglage de langue : la langue par app de macOS (Réglages Système › Langue et région › Applications) s'applique.

#### Scenario: Système en français
- **GIVEN** la langue principale de macOS est le français
- **WHEN** l'utilisateur lance Cairn
- **THEN** l'interface est en français

#### Scenario: Système en anglais
- **GIVEN** la langue principale de macOS est l'anglais
- **WHEN** l'utilisateur lance Cairn
- **THEN** l'interface est en anglais

#### Scenario: Langue non prise en charge
- **GIVEN** la langue principale de macOS est l'allemand, sans le français avant l'anglais dans la liste des langues préférées
- **WHEN** l'utilisateur lance Cairn
- **THEN** l'interface est en anglais

#### Scenario: Langue choisie pour l'app seule
- **GIVEN** macOS est en anglais et l'utilisateur a choisi le français pour Cairn dans les réglages système
- **WHEN** il relance Cairn
- **THEN** l'interface est en français

### Requirement: Pluriels et nombres traduits
Le système SHALL accorder les textes qui contiennent un nombre (articles sélectionnés, nouveaux articles, non lus) selon les règles de pluriel de la langue affichée.

#### Scenario: Un ou plusieurs articles
- **WHEN** l'utilisateur sélectionne un article, puis trois
- **THEN** l'interface affiche « 1 article sélectionné » puis « 3 articles sélectionnés » en français, « 1 article selected » puis « 3 articles selected » en anglais

### Requirement: Données de l'utilisateur non traduites
Le système MUST NOT traduire ni renommer les données déjà enregistrées : noms de cairns, de dossiers et de tags, titres d'abonnements, résumés et digests déjà produits.

#### Scenario: Changement de langue
- **GIVEN** un cairn nommé « Lectures » et un résumé produit en français
- **WHEN** l'utilisateur relance Cairn avec le système en anglais
- **THEN** le cairn s'appelle toujours « Lectures » et le résumé reste en français
