## ADDED Requirements

### Requirement: S'abonner depuis un lien feed:
Le système SHALL ouvrir les liens `feed:`, sous la forme `feed:` suivi d'une adresse complète ou `feed://` suivi d'une adresse sans schéma, en affichant « Ajouter un abonnement » pré-rempli de l'adresse du flux. L'abonnement MUST n'être ajouté qu'après confirmation de l'utilisateur, comme une adresse saisie.

#### Scenario: Lien avec adresse complète
- **WHEN** l'utilisateur ouvre le lien `feed:https://exemple.com/rss`
- **THEN** Cairn passe au premier plan et propose d'ajouter `https://exemple.com/rss`

#### Scenario: Lien sans schéma
- **WHEN** l'utilisateur ouvre le lien `feed://exemple.com/rss`
- **THEN** Cairn propose d'ajouter `exemple.com/rss`, complété en https comme une adresse saisie
