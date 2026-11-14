## MODIFIED Requirements

### Requirement: Purger les articles non gardés
Le système SHALL supprimer automatiquement, au lancement, les articles non gardés dont la date de publication dépasse la durée de conservation réglée (« Conserver les articles non gardés » : 7, 14 ou 30 jours, 2, 3 ou 6 mois, 1 an ; 30 jours par défaut). Les articles gardés MUST NOT être purgés.

#### Scenario: Article ancien non gardé
- **GIVEN** la durée de conservation est de 30 jours
- **WHEN** l'application démarre et qu'un article non gardé a plus de 30 jours
- **THEN** cet article est supprimé

#### Scenario: Article ancien gardé
- **WHEN** l'application démarre et qu'un article gardé dépasse la durée de conservation
- **THEN** cet article est conservé

#### Scenario: Durée allongée
- **GIVEN** la durée de conservation est de 3 mois
- **WHEN** l'application démarre et qu'un article non gardé a 45 jours
- **THEN** cet article est conservé

## ADDED Requirements

### Requirement: Ordre des articles
Le système SHALL proposer dans le menu Présentation « Ordre des articles » : « Plus récents d'abord » (par défaut) ou « Plus anciens d'abord ». Le choix MUST s'appliquer à toutes les listes d'articles et être conservé entre les lancements.

#### Scenario: Plus anciens d'abord
- **WHEN** l'utilisateur choisit « Plus anciens d'abord »
- **THEN** la liste affichée commence par l'article le plus ancien

#### Scenario: Cairn
- **GIVEN** l'ordre est « Plus anciens d'abord »
- **WHEN** l'utilisateur affiche un cairn
- **THEN** ses articles commencent par le premier gardé
