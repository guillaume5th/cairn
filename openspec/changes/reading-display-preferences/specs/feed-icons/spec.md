# Spec Delta

## MODIFIED Requirements

### Requirement: Afficher l'icône de la source
Le système SHALL afficher l'icône de l'abonnement devant son nom dans la barre latérale, à gauche de chaque ligne de la liste d'articles, et devant le nom de la source dans l'en-tête de l'article affiché. L'icône MUST être présentée dans un cercle au style Liquid Glass du système, sans déformer ses proportions. Dans la barre latérale et l'en-tête, le cercle MUST avoir la taille du texte qu'il accompagne. L'icône des lignes de la liste d'articles MUST pouvoir être masquée depuis le menu Présentation ; ce choix est conservé d'un lancement à l'autre et ne concerne ni la barre latérale ni l'en-tête de l'article.

#### Scenario: Barre latérale
- **WHEN** l'utilisateur consulte la liste des abonnements
- **THEN** chaque abonnement est précédé de son icône

#### Scenario: Liste d'articles
- **WHEN** l'utilisateur consulte une liste d'articles avec la case « Icônes dans la liste d'articles » cochée (par défaut)
- **THEN** chaque ligne commence à gauche par l'icône de sa source dans un cercle

#### Scenario: Icônes masquées dans la liste
- **WHEN** l'utilisateur décoche « Icônes dans la liste d'articles »
- **THEN** les lignes de la liste d'articles n'affichent plus d'icône, la pastille des non lus reste affichée, et la barre latérale et l'en-tête de l'article gardent leurs icônes

#### Scenario: Article affiché
- **WHEN** l'utilisateur affiche un article
- **THEN** le nom de la source dans l'en-tête est précédé de l'icône de cette source
