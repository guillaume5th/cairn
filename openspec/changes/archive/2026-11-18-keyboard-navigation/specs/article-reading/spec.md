# Spec Delta

## ADDED Requirements

### Requirement: Article suivant et précédent au clavier
Le système SHALL ouvrir, quand la liste d'articles a le focus, l'article qui suit l'article courant dans la liste affichée (plus bas) avec `k`, et celui qui le précède (plus haut) avec `j`, comme un clic : l'article s'affiche, marqué comme lu, et la liste défile jusqu'à lui. Au bout de la liste, le système MUST émettre le son d'alerte et ne rien changer. En mode sélection, ces touches MUST NOT agir.

#### Scenario: Article suivant
- **GIVEN** l'article courant est le deuxième de la liste
- **WHEN** l'utilisateur appuie sur `k`
- **THEN** le troisième article s'affiche, marqué comme lu, et la liste défile jusqu'à lui

#### Scenario: Article précédent
- **GIVEN** l'article courant est le deuxième de la liste
- **WHEN** l'utilisateur appuie sur `j`
- **THEN** le premier article s'affiche

#### Scenario: Bout de la liste
- **GIVEN** l'article courant est le dernier de la liste
- **WHEN** l'utilisateur appuie sur `k`
- **THEN** le son d'alerte retentit et l'article courant reste affiché

#### Scenario: Aucun article courant
- **GIVEN** aucun article n'est sélectionné dans une liste non vide
- **WHEN** l'utilisateur appuie sur `j` ou sur `k`
- **THEN** le premier article de la liste s'affiche

#### Scenario: Mode sélection
- **WHEN** la liste est en mode sélection et que l'utilisateur appuie sur `j`
- **THEN** rien ne change

### Requirement: Garder au clavier
Le système SHALL, quand la liste d'articles a le focus et qu'un seul article est affiché, garder cet article avec `s`, ou le retirer de son cairn s'il est déjà gardé, avec la même confirmation que « Retirer du cairn » pour un article qui a une note ou des tags. Avec plusieurs cairns, l'article MUST être gardé dans le dernier cairn utilisé, celui de l'article gardé le plus récemment, et à défaut dans le premier cairn par ordre alphabétique.

#### Scenario: Garder avec un seul cairn
- **GIVEN** un seul cairn et un article affiché non gardé
- **WHEN** l'utilisateur appuie sur `s`
- **THEN** l'article est gardé dans ce cairn

#### Scenario: Dernier cairn utilisé
- **GIVEN** deux cairns « Veille » et « Lectures », et l'article gardé le plus récemment est dans « Lectures »
- **WHEN** l'utilisateur appuie sur `s` sur un article non gardé
- **THEN** l'article est gardé dans « Lectures »

#### Scenario: Aucun article encore gardé
- **GIVEN** deux cairns « Veille » et « Lectures » et aucun article gardé
- **WHEN** l'utilisateur appuie sur `s`
- **THEN** l'article est gardé dans « Lectures », premier par ordre alphabétique

#### Scenario: Retirer un article gardé
- **GIVEN** l'article affiché est gardé, sans note ni tag
- **WHEN** l'utilisateur appuie sur `s`
- **THEN** l'article est retiré de son cairn

#### Scenario: Retirer un article annoté
- **GIVEN** l'article affiché est gardé et a une note
- **WHEN** l'utilisateur appuie sur `s`
- **THEN** une confirmation annonce que ses notes et ses tags seront perdus, et l'article reste gardé tant qu'elle n'est pas acceptée
