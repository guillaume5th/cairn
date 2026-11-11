## ADDED Requirements

### Requirement: Plusieurs cairns
Le système SHALL permettre de créer des cairns nommés, de les renommer et de les supprimer. Deux cairns MUST NOT porter le même nom (casse et accents ignorés). Il MUST toujours exister au moins un cairn ; à défaut, un cairn « Cairn » est créé et reçoit les articles gardés. La suppression d'un cairn MUST retirer ses articles du cairn, avec leur note et leurs tags, après une confirmation indiquant leur nombre.

#### Scenario: Créer un cairn
- **WHEN** l'utilisateur crée un cairn nommé « Pro »
- **THEN** « Pro » apparaît dans la section Cairns, vide

#### Scenario: Nom déjà pris
- **WHEN** l'utilisateur crée ou renomme un cairn avec le nom « pro » alors qu'un cairn « Pro » existe
- **THEN** aucun cairn n'est créé ni renommé et l'utilisateur en est informé

#### Scenario: Premier lancement après la mise à jour
- **WHEN** l'utilisateur lance l'application avec des articles déjà gardés et aucun cairn
- **THEN** un cairn « Cairn » contient tous ces articles, avec leurs notes et leurs tags

#### Scenario: Supprimer un cairn
- **WHEN** l'utilisateur supprime le cairn « Pro » qui contient 3 articles et confirme
- **THEN** « Pro » disparaît et ses 3 articles ne sont plus gardés, sans note ni tag

#### Scenario: Dernier cairn
- **WHEN** il ne reste qu'un cairn
- **THEN** l'action de suppression de ce cairn est indisponible

### Requirement: Déplacer un article entre cairns
Le système SHALL permettre de déplacer un article gardé vers un autre cairn. Le déplacement MUST conserver sa note et ses tags.

#### Scenario: Déplacement
- **WHEN** l'utilisateur déplace un article annoté et tagué du cairn « Perso » vers « Pro »
- **THEN** l'article n'est plus dans « Perso », apparaît dans « Pro » avec sa note et ses tags

## MODIFIED Requirements

### Requirement: Garder un article
Le système SHALL permettre de garder un article dans un cairn choisi et de ne plus le garder. Un article gardé MUST être dans un seul cairn. Quand il n'existe qu'un cairn, garder un article MUST le ranger dans ce cairn sans demander de choix. Un article gardé MUST rester disponible même si son abonnement est supprimé ou s'il disparaît du flux.

#### Scenario: Garder un article
- **WHEN** l'utilisateur garde un article dans le cairn « Pro »
- **THEN** l'article apparaît dans la vue de « Pro » et dans aucun autre cairn

#### Scenario: Un seul cairn
- **WHEN** il n'existe qu'un cairn et que l'utilisateur garde un article
- **THEN** l'article est gardé dans ce cairn, sans menu de choix

#### Scenario: Ne plus garder
- **WHEN** l'utilisateur retire un article de son cairn
- **THEN** l'article disparaît de la vue de ce cairn et redevient soumis à la purge

### Requirement: Vue Cairn
Le système SHALL proposer une vue par cairn listant ses articles gardés, du plus récemment gardé au plus ancien.

#### Scenario: Consultation du cairn
- **WHEN** l'utilisateur ouvre la vue du cairn « Pro »
- **THEN** seuls les articles gardés dans « Pro » sont listés, du plus récemment gardé au plus ancien

### Requirement: Tags
Le système SHALL permettre d'ajouter et retirer des tags sur un article gardé, en réutilisant les tags existants de tous les cairns. Les tags MUST être insensibles à la casse (« Swift » et « swift » sont le même tag). Sous chaque cairn, la barre latérale MUST n'afficher que les tags portés par les articles de ce cairn.

#### Scenario: Ajout d'un tag existant
- **WHEN** l'utilisateur tape le début d'un tag déjà utilisé, dans ce cairn ou un autre
- **THEN** le tag existant est proposé

#### Scenario: Tags d'un cairn
- **WHEN** le tag « swift » n'est porté que par des articles du cairn « Pro »
- **THEN** « swift » apparaît sous « Pro » et pas sous les autres cairns

#### Scenario: Filtrer par tag
- **WHEN** l'utilisateur sélectionne le tag « swift » sous le cairn « Pro »
- **THEN** seuls les articles de « Pro » portant ce tag sont affichés
