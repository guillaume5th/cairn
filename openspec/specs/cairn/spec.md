# cairn Specification

## Purpose

Le cairn conserve durablement les articles que l'utilisateur juge dignes d'être retenus, avec ses propres notes et tags, et permet de les retrouver par recherche.

## Requirements

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

### Requirement: Supprimer un article orphelin
Le système SHALL permettre de supprimer manuellement, après confirmation, un article dont l'abonnement a été supprimé, qu'il soit gardé ou non. Un article d'un abonnement suivi MUST NOT être supprimable manuellement, car le prochain rafraîchissement le recréerait.

#### Scenario: Suppression d'un article orphelin
- **WHEN** l'utilisateur supprime un article dont l'abonnement a été supprimé et confirme
- **THEN** l'article disparaît définitivement, avec sa note et ses tags

#### Scenario: Article d'un abonnement suivi
- **WHEN** l'utilisateur affiche le menu contextuel d'un article d'un abonnement suivi
- **THEN** aucune action de suppression n'est proposée

### Requirement: Vue Cairn
Le système SHALL proposer une vue par cairn listant ses articles gardés, du plus récemment gardé au plus ancien.

#### Scenario: Consultation du cairn
- **WHEN** l'utilisateur ouvre la vue du cairn « Pro »
- **THEN** seuls les articles gardés dans « Pro » sont listés, du plus récemment gardé au plus ancien

### Requirement: Note personnelle
Le système SHALL permettre d'écrire et modifier une note texte libre sur un article gardé. La note MUST être enregistrée sans action explicite de sauvegarde.

#### Scenario: Saisie d'une note
- **WHEN** l'utilisateur écrit une note sur un article gardé puis relance l'application
- **THEN** la note est toujours présente

#### Scenario: Retrait d'un article annoté
- **WHEN** l'utilisateur retire du cairn un article qui a une note
- **THEN** une confirmation lui est demandée avant de perdre la note

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
