# Spec Delta

## ADDED Requirements

### Requirement: Couleur d'un cairn
Le système SHALL permettre de donner à un cairn une couleur parmi rouge, orange, jaune, vert, bleu, violet et gris, ou aucune, depuis son menu contextuel dans la barre latérale. Un cairn sans couleur MUST garder la couleur d'accent. Le symbole du cairn dans la barre latérale et la marque « gardé » d'une ligne d'article MUST prendre la couleur du cairn de l'article.

#### Scenario: Choisir une couleur
- **GIVEN** un cairn « Pro » sans couleur
- **WHEN** l'utilisateur choisit Couleur > Bleu dans le menu contextuel de « Pro »
- **THEN** le symbole de « Pro » dans la barre latérale devient bleu, et la marque « gardé » des articles de « Pro » dans la liste aussi

#### Scenario: Deux cairns
- **GIVEN** « Pro » est bleu et « Recettes » est vert
- **WHEN** la liste « Tous les articles » contient un article gardé de chacun
- **THEN** la marque de l'un est bleue et celle de l'autre verte

#### Scenario: Retirer la couleur
- **WHEN** l'utilisateur choisit Couleur > Aucune pour « Pro »
- **THEN** son symbole et ses marques reprennent la couleur d'accent

#### Scenario: Ligne sélectionnée
- **GIVEN** un article gardé dans un cairn bleu
- **WHEN** sa ligne est sélectionnée
- **THEN** sa marque « gardé » est blanche, lisible sur la surbrillance

#### Scenario: Cairn sélectionné dans la barre latérale
- **GIVEN** un cairn bleu
- **WHEN** l'utilisateur sélectionne ce cairn dans la barre latérale
- **THEN** son symbole est blanc, lisible sur la surbrillance

#### Scenario: Pastilles du menu
- **WHEN** l'utilisateur ouvre le sous-menu Couleur d'un cairn
- **THEN** chaque couleur est précédée d'une pastille de cette couleur

#### Scenario: Article déplacé
- **GIVEN** un article gardé dans « Pro », bleu
- **WHEN** l'utilisateur le déplace dans « Recettes », vert
- **THEN** sa marque devient verte

#### Scenario: Autre Mac
- **WHEN** l'utilisateur colore un cairn sur un Mac synchronisé par iCloud
- **THEN** le cairn prend la même couleur sur l'autre Mac
