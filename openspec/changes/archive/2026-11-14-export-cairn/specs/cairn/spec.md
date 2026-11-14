## ADDED Requirements

### Requirement: Exporter un cairn en Markdown
Le système SHALL proposer, dans le menu contextuel d'un cairn, « Exporter en Markdown… », qui enregistre à l'endroit choisi un fichier `.md` nommé d'après le cairn. Le fichier MUST contenir le nom du cairn puis chaque article, du plus récemment gardé au plus ancien : titre en lien vers l'article, source, dates de publication et de garde, tags et note.

#### Scenario: Cairn avec un article annoté
- **GIVEN** le cairn « Lectures » contient un article tagué « swift » avec la note « À relire »
- **WHEN** l'utilisateur exporte « Lectures » en Markdown
- **THEN** le fichier « Lectures.md » contient le titre de l'article en lien, le tag « swift » et la note « À relire »

#### Scenario: Cairn vide
- **WHEN** l'utilisateur exporte un cairn sans article
- **THEN** le fichier contient le nom du cairn et indique qu'il ne contient aucun article
