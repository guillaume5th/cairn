## ADDED Requirements

### Requirement: Renommer un abonnement
Le système SHALL proposer « Renommer… » dans le menu contextuel d'un abonnement. Le nouveau titre MUST remplacer celui du flux dans la barre latérale, la liste d'articles et les articles déjà reçus, et MUST être conservé aux rafraîchissements suivants. Un titre vide MUST être refusé.

#### Scenario: Titre plus court
- **WHEN** l'utilisateur renomme « Simon Willison's Weblog » en « Simon »
- **THEN** la barre latérale et les lignes de ses articles affichent « Simon »

#### Scenario: Rafraîchissement
- **GIVEN** un abonnement renommé
- **WHEN** ses flux sont rafraîchis
- **THEN** il garde le titre choisi par l'utilisateur

#### Scenario: Titre vide
- **WHEN** l'utilisateur valide un titre vide
- **THEN** une erreur s'affiche et le titre ne change pas
