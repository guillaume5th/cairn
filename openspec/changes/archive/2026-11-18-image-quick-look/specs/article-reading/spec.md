# Spec Delta

## ADDED Requirements

### Requirement: Agrandir une image avec Coup d'œil
Le système SHALL ouvrir dans Coup d'œil l'image d'un article sur laquelle l'utilisateur clique, avec les autres images de l'article parcourables depuis Coup d'œil. Une image qui est un lien MUST garder le comportement d'un lien. Le contenu de l'article MUST rester affiché sans exécuter de script de l'article.

#### Scenario: Clic sur une image
- **GIVEN** un article qui contient trois images
- **WHEN** l'utilisateur clique sur la deuxième
- **THEN** Coup d'œil s'ouvre sur cette image, et les flèches passent à la première et à la troisième

#### Scenario: Image dans un lien
- **WHEN** l'utilisateur clique sur une image qui est un lien
- **THEN** le lien s'ouvre dans le navigateur par défaut, sans Coup d'œil

#### Scenario: Image impossible à charger
- **GIVEN** une image de l'article dont l'adresse ne répond plus
- **WHEN** l'utilisateur clique sur une autre image
- **THEN** Coup d'œil s'ouvre sur l'image cliquée, sans l'image indisponible

#### Scenario: Changement d'article
- **GIVEN** Coup d'œil affiche une image de l'article
- **WHEN** l'utilisateur sélectionne un autre article
- **THEN** Coup d'œil se ferme et les images téléchargées pour l'article précédent sont effacées

#### Scenario: Article sans script
- **WHEN** un article contenant des images est affiché
- **THEN** aucun script fourni par le flux ne s'exécute, et le clic sur une image fonctionne quand même
