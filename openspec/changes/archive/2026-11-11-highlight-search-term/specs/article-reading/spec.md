# Spec Delta

## ADDED Requirements

### Requirement: Surligner le terme recherché
Pendant une recherche, le système SHALL surligner le terme recherché dans la liste et dans l'article affiché, selon la même règle que la recherche (sans tenir compte de la casse ni des accents). Une ligne dont le titre ne contient pas le terme MUST afficher un court extrait autour de sa première occurrence dans le contenu, la note ou les tags. Le surlignage MUST NOT exécuter de script de l'article.

#### Scenario: Terme dans le titre
- **WHEN** l'utilisateur recherche un mot présent dans le titre d'un article
- **THEN** ce mot est surligné dans le titre de la ligne, sans extrait supplémentaire

#### Scenario: Terme hors du titre
- **WHEN** l'utilisateur recherche un mot présent dans le contenu, la note ou un tag d'un article, mais pas dans son titre
- **THEN** la ligne affiche sous le titre un court extrait autour de la première occurrence, mot surligné

#### Scenario: Surlignage sans accent
- **WHEN** l'utilisateur recherche « deploiement » et qu'un article contient « Déploiement »
- **THEN** « Déploiement » est surligné

#### Scenario: Article affiché
- **WHEN** l'utilisateur affiche un article pendant une recherche
- **THEN** toutes les occurrences du terme sont surlignées dans son titre et son contenu, et le contenu défile jusqu'à la première

#### Scenario: Fin de la recherche
- **WHEN** l'utilisateur efface le texte recherché
- **THEN** le surlignage et les extraits disparaissent de la liste et de l'article
