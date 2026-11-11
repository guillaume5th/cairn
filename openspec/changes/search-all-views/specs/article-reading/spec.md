# Spec Delta

## ADDED Requirements

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
- **THEN** le champ de recherche est vide et la nouvelle liste est complète
