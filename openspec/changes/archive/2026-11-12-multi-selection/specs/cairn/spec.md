# Spec Delta

## ADDED Requirements

### Requirement: Garder plusieurs articles
Le système SHALL permettre de garder toute la sélection dans un cairn choisi. Les articles pas encore gardés y sont gardés ; ceux déjà gardés dans un autre cairn y sont déplacés avec leur note et leurs tags. Quand il n'existe qu'un cairn, l'action « Garder dans le cairn » MUST garder les articles qui ne le sont pas encore, sans demander de cairn.

#### Scenario: Garder une sélection mixte
- **GIVEN** il existe les cairns « Veille » et « Lire plus tard », et deux articles non gardés et un article gardé dans « Lire plus tard » sont sélectionnés
- **WHEN** l'utilisateur choisit « Garder dans » puis « Veille »
- **THEN** les trois articles sont dans « Veille », et l'article déplacé garde sa note et ses tags

#### Scenario: Un seul cairn
- **GIVEN** il n'existe qu'un cairn et trois articles non gardés sont sélectionnés
- **WHEN** l'utilisateur choisit « Garder dans le cairn »
- **THEN** les trois articles sont gardés dans ce cairn

### Requirement: Retirer plusieurs articles du cairn
Le système SHALL proposer « Retirer du cairn » quand tous les articles sélectionnés sont gardés, et retirer alors toute la sélection. Si au moins un d'eux a une note ou des tags, le système MUST demander une seule confirmation pour tout le lot, qui indique combien d'articles perdront leur note ou leurs tags.

#### Scenario: Retirer sans note
- **GIVEN** trois articles gardés sans note ni tag sont sélectionnés
- **WHEN** l'utilisateur choisit « Retirer du cairn »
- **THEN** les trois articles ne sont plus gardés, sans confirmation

#### Scenario: Retirer avec des notes
- **GIVEN** trois articles gardés sont sélectionnés et deux ont une note
- **WHEN** l'utilisateur choisit « Retirer du cairn »
- **THEN** une seule confirmation indique que 2 articles perdront leur note ou leurs tags, et les trois sont retirés si l'utilisateur confirme

#### Scenario: Sélection en partie non gardée
- **WHEN** la sélection contient au moins un article non gardé
- **THEN** « Retirer du cairn » n'est pas proposé

### Requirement: Supprimer plusieurs articles orphelins
Le système SHALL permettre de supprimer d'un coup, après une seule confirmation, une sélection dont tous les articles ont perdu leur abonnement. Quand la sélection contient au moins un article d'un abonnement suivi, la suppression MUST NOT être proposée.

#### Scenario: Supprimer trois orphelins
- **GIVEN** trois articles dont l'abonnement a été supprimé sont sélectionnés
- **WHEN** l'utilisateur choisit « Supprimer 3 articles… » ou appuie sur Supprimer, puis confirme
- **THEN** les trois articles sont supprimés

#### Scenario: Sélection avec un article suivi
- **WHEN** la sélection contient un article d'un abonnement suivi
- **THEN** la suppression n'est pas proposée et la touche Supprimer est sans effet
