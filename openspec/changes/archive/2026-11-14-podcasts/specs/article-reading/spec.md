## ADDED Requirements

### Requirement: Écouter un épisode de podcast
Le système SHALL retenir, à l'import, le fichier audio joint à un article (enclosure RSS, lien Atom « enclosure », pièce jointe JSON Feed) et afficher sous l'en-tête de cet article le lecteur audio du système. La lecture MUST s'arrêter quand l'utilisateur change d'article. Un article sans audio MUST NOT afficher de lecteur.

#### Scenario: Épisode avec audio
- **GIVEN** un flux dont un article joint `episode.mp3` de type `audio/mpeg`
- **WHEN** l'utilisateur ouvre cet article
- **THEN** un lecteur permet d'écouter `episode.mp3`

#### Scenario: Article sans audio
- **WHEN** l'utilisateur ouvre un article sans fichier audio joint
- **THEN** aucun lecteur n'est affiché
