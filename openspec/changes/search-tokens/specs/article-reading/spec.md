# Spec Delta

## ADDED Requirements

### Requirement: Filtrer par jetons de recherche
Le système SHALL accepter dans le champ de recherche d'une liste d'articles des jetons de filtre : une source, un tag, « Non lus », « Gardés ». Il MUST proposer, pendant la frappe, les jetons qui correspondent au texte saisi, parmi les sources et les tags des articles de la liste affichée. Les jetons d'un même type MUST élargir la liste, ceux de types différents la restreindre, et le texte recherché s'applique en plus.

#### Scenario: Proposition d'une source
- **GIVEN** la liste « Tous les articles » contient des articles de l'abonnement « Korben »
- **WHEN** l'utilisateur tape « kor » dans le champ de recherche
- **THEN** le jeton de source « Korben » est proposé, et le choisir remplace le texte tapé par ce jeton

#### Scenario: Préfixe de type
- **WHEN** l'utilisateur tape « tag: » dans le champ de recherche
- **THEN** seuls des jetons de tag sont proposés

#### Scenario: Jeton de source
- **WHEN** le champ contient le jeton de source « Korben »
- **THEN** seuls les articles de cet abonnement sont listés

#### Scenario: Deux sources
- **WHEN** le champ contient les jetons de source « Korben » et « Xavki »
- **THEN** les articles de l'un et de l'autre sont listés, et aucun autre

#### Scenario: Types combinés avec du texte
- **WHEN** le champ contient le jeton de tag « swift », le jeton « Non lus » et le texte « concurrency »
- **THEN** seuls les articles non lus, tagués « swift », qui contiennent « concurrency » sont listés

#### Scenario: Jeton « Gardés »
- **WHEN** le champ contient le jeton « Gardés » dans « Tous les articles »
- **THEN** seuls les articles gardés sont listés

#### Scenario: Tag sans tenir compte de la casse ni des accents
- **GIVEN** un article gardé tagué « Sécurité » et un autre tagué « securite »
- **WHEN** le champ contient le jeton de tag « Sécurité »
- **THEN** les deux articles sont listés

#### Scenario: Résumés quotidiens
- **WHEN** l'utilisateur recherche dans la vue « Résumés quotidiens »
- **THEN** aucun jeton n'est proposé et la recherche porte sur le texte seul

## MODIFIED Requirements

### Requirement: Rechercher dans la liste courante
Le système SHALL proposer un champ de recherche dans toutes les vues de la barre latérale (« Tous les articles », chaque abonnement, Cairn et chaque tag). Il MUST limiter la liste aux articles dont le titre, le contenu, la note ou un tag contient le texte recherché, sans tenir compte de la casse ni des accents. Le raccourci ⌘F MUST placer le curseur dans ce champ.

#### Scenario: Recherche dans « Tous les articles »
- **WHEN** l'utilisateur recherche un mot présent dans le titre d'un article non gardé de « Tous les articles »
- **THEN** cet article figure dans les résultats, et les articles qui ne contiennent pas ce mot n'y figurent pas

#### Scenario: Recherche dans un abonnement
- **WHEN** l'utilisateur recherche un mot dans la vue d'un abonnement
- **THEN** seuls les articles de cet abonnement qui contiennent ce mot sont listés

#### Scenario: Recherche dans une note
- **WHEN** l'utilisateur recherche un mot qui n'apparaît que dans la note d'un article gardé
- **THEN** cet article figure dans les résultats

#### Scenario: Recherche sans accent
- **WHEN** l'utilisateur recherche « deploiement » et qu'un article de la liste contient « Déploiement »
- **THEN** cet article figure dans les résultats

#### Scenario: Recherche et filtre « Non lus »
- **WHEN** le filtre « Non lus » est actif et que l'utilisateur recherche un mot
- **THEN** seuls les articles non lus qui contiennent ce mot sont listés

#### Scenario: Raccourci ⌘F
- **WHEN** l'utilisateur appuie sur ⌘F, quelle que soit la vue affichée
- **THEN** le curseur est placé dans le champ de recherche de cette vue, sans changer de vue

#### Scenario: Changement d'entrée
- **WHEN** l'utilisateur change d'entrée dans la barre latérale après une recherche
- **THEN** le champ de recherche est vide, sans texte ni jeton, et la nouvelle liste est complète
