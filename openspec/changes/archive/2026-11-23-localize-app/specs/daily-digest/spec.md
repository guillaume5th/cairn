# Spec Delta

## MODIFIED Requirements

### Requirement: Contenu du résumé
Le système SHALL, pour produire un résumé, rafraîchir d'abord les abonnements puis résumer les articles publiés dans les 24 heures précédant le moment du résumé, tous abonnements confondus. Le résumé MUST être rédigé dans la langue de l'interface (français ou anglais), regrouper les sujets proches, et être suivi de la liste des articles résumés avec leur titre, leur source et un lien vers chacun.

#### Scenario: Articles du jour
- **GIVEN** cinq articles ont été publiés dans les 24 dernières heures et d'autres avant
- **WHEN** le résumé est produit
- **THEN** il porte sur ces cinq articles seulement, et les cinq figurent dans la liste qui le suit

#### Scenario: Lien vers un article
- **WHEN** l'utilisateur clique sur un article de la liste d'un résumé
- **THEN** l'article s'ouvre dans le navigateur

#### Scenario: Aucun article
- **WHEN** aucun article n'a été publié dans les 24 dernières heures au moment du résumé
- **THEN** aucun résumé n'est créé et l'IA n'est pas appelée

#### Scenario: Digest dans la langue de l'interface
- **GIVEN** l'interface est en anglais
- **WHEN** le résumé du jour est produit
- **THEN** le moteur reçoit la consigne de rédiger le résumé en anglais
