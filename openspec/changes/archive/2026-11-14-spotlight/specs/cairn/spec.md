## ADDED Requirements

### Requirement: Articles gardés dans Spotlight
Le système SHALL indexer dans Spotlight chaque article gardé, avec son titre, sa source, sa note, ses tags et le nom de son cairn, et MUST tenir l'index à jour peu après chaque changement (garde, retrait, note, tags, cairn, restauration). Les articles non gardés MUST NOT être indexés. Choisir un résultat SHALL ouvrir Cairn sur cet article, dans son cairn.

#### Scenario: Recherche d'une note
- **GIVEN** un article gardé avec la note « comparatif des prix »
- **WHEN** l'utilisateur cherche « comparatif » dans Spotlight
- **THEN** l'article figure dans les résultats

#### Scenario: Article retiré du cairn
- **WHEN** l'utilisateur retire un article de son cairn
- **THEN** il disparaît des résultats Spotlight

#### Scenario: Ouverture d'un résultat
- **WHEN** l'utilisateur choisit un article gardé dans Spotlight
- **THEN** Cairn passe au premier plan et affiche cet article dans son cairn
