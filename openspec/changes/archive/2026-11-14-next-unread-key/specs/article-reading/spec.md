## ADDED Requirements

### Requirement: Aller au prochain non lu
Le système SHALL ouvrir, quand la liste d'articles a le focus et que l'utilisateur appuie sur Espace ou N, le prochain article non lu de la liste affichée après l'article courant, en reprenant en haut après le dernier. L'article ouvert MUST être marqué comme lu et rendu visible dans la liste. Sans article non lu, le système MUST émettre le son d'alerte et ne rien changer.

#### Scenario: Article non lu plus bas
- **GIVEN** l'article courant est le deuxième de la liste et le cinquième est le premier non lu après lui
- **WHEN** l'utilisateur appuie sur Espace
- **THEN** le cinquième article s'affiche, marqué comme lu, et la liste défile jusqu'à lui

#### Scenario: Reprise en haut
- **GIVEN** aucun article non lu après l'article courant, mais un non lu plus haut
- **WHEN** l'utilisateur appuie sur N
- **THEN** ce non lu plus haut s'affiche

#### Scenario: Tout est lu
- **WHEN** l'utilisateur appuie sur Espace et qu'aucun article de la liste n'est non lu
- **THEN** le son d'alerte retentit et l'article courant reste affiché

#### Scenario: Espace dans l'article
- **WHEN** le focus est dans l'article affiché et que l'utilisateur appuie sur Espace
- **THEN** l'article défile, sans changer d'article
