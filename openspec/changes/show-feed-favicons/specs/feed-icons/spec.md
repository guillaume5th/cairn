# Spec Delta

## Purpose

Donne à chaque source un repère visuel, l'icône de son site, pour reconnaître d'un coup d'œil d'où vient un article dans la barre latérale, la liste d'articles et le panneau de lecture.

## ADDED Requirements

### Requirement: Récupérer l'icône d'un abonnement
Le système SHALL récupérer l'icône du site de chaque abonnement, en retenant la première source disponible dans cet ordre : l'icône déclarée par le flux, l'icône déclarée par la page d'accueil du site, puis l'icône à l'emplacement conventionnel `/favicon.ico` du site. Une icône MUST être une image lisible ; sinon la source suivante est essayée.

#### Scenario: Icône déclarée par le flux
- **WHEN** un flux déclare une icône et que cette icône est une image lisible
- **THEN** cette icône devient celle de l'abonnement

#### Scenario: Icône déclarée par la page d'accueil
- **WHEN** le flux ne déclare pas d'icône et que la page d'accueil du site en déclare une, lisible
- **THEN** cette icône devient celle de l'abonnement

#### Scenario: Icône conventionnelle
- **WHEN** ni le flux ni la page d'accueil ne déclarent d'icône et que le site répond à `/favicon.ico` avec une image lisible
- **THEN** cette icône devient celle de l'abonnement

#### Scenario: Aucune icône
- **WHEN** aucune des sources ne fournit d'image lisible
- **THEN** l'abonnement reste sans icône et aucune erreur n'est signalée pour cet abonnement

### Requirement: Conserver et revérifier l'icône
Le système SHALL conserver l'icône d'un abonnement localement, pour l'afficher hors ligne et sans la retélécharger à chaque lancement. Le système MUST rechercher l'icône à l'ajout de l'abonnement, puis la revérifier lors d'un rafraîchissement au plus une fois tous les 7 jours, que la précédente recherche ait abouti ou non. Un échec de recherche MUST NOT effacer une icône déjà conservée ni bloquer le rafraîchissement des articles.

#### Scenario: Ajout d'un abonnement
- **WHEN** l'utilisateur ajoute un abonnement dont le site a une icône
- **THEN** l'icône s'affiche pour cet abonnement sans attendre le rafraîchissement suivant

#### Scenario: Hors ligne
- **WHEN** l'application démarre sans connexion réseau
- **THEN** les icônes déjà récupérées s'affichent

#### Scenario: Revérification espacée
- **WHEN** l'utilisateur rafraîchit plusieurs fois dans la même journée
- **THEN** l'icône de chaque abonnement est recherchée au plus une fois sur cette période

#### Scenario: Site injoignable lors d'une revérification
- **WHEN** la revérification de l'icône d'un abonnement échoue alors qu'une icône était conservée
- **THEN** l'icône conservée reste affichée et les articles de l'abonnement sont rafraîchis normalement

### Requirement: Afficher l'icône de la source
Le système SHALL afficher l'icône de l'abonnement devant son nom dans la barre latérale, devant le nom de la source dans chaque ligne de la liste d'articles, et devant le nom de la source dans l'en-tête de l'article affiché. L'icône MUST être affichée à la taille du texte qu'elle accompagne, sans déformer ses proportions.

#### Scenario: Barre latérale
- **WHEN** l'utilisateur consulte la liste des abonnements
- **THEN** chaque abonnement est précédé de son icône

#### Scenario: Liste d'articles
- **WHEN** l'utilisateur consulte une liste d'articles
- **THEN** le nom de la source de chaque article est précédé de l'icône de cette source

#### Scenario: Article affiché
- **WHEN** l'utilisateur affiche un article
- **THEN** le nom de la source dans l'en-tête est précédé de l'icône de cette source

### Requirement: Icône générique de repli
Le système SHALL afficher une icône générique, identique pour toutes les sources, partout où une source n'a pas d'icône, afin que les noms restent alignés.

#### Scenario: Abonnement sans icône
- **WHEN** un abonnement n'a pas d'icône (pas encore récupérée, introuvable ou illisible)
- **THEN** l'icône générique est affichée à sa place dans la barre latérale, la liste d'articles et l'en-tête de l'article

### Requirement: Icône des articles gardés orphelins
Le système SHALL conserver, pour chaque article gardé, l'icône de sa source lorsque son abonnement est supprimé, comme il conserve déjà le nom de la source.

#### Scenario: Suppression de l'abonnement d'un article gardé
- **WHEN** l'utilisateur supprime un abonnement qui avait une icône et dont un article est gardé
- **THEN** l'article gardé continue d'afficher l'icône de sa source dans le cairn et dans son en-tête
