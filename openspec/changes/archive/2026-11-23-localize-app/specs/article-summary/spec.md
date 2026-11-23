# Spec Delta

## MODIFIED Requirements

### Requirement: Résumer l'article consulté
Le système SHALL proposer, dans la barre d'outils de l'article affiché, une action « Résumer » qui le fait résumer, dans la langue de l'interface (français ou anglais), par le moteur d'IA des réglages (Apple Intelligence, Ollama, Claude Code ou Claude API), à partir de son titre et de son texte intégral quand il a été chargé, sinon du contenu fourni par le flux. Le résumé lui-même MUST NOT télécharger quoi que ce soit depuis le site de l'article. L'action MUST être indisponible sans contenu ou pendant un résumé en cours de cet article. Aucun résumé d'article n'est produit sans demande.

#### Scenario: Résumer un article
- **GIVEN** l'article affiché a un contenu et pas encore de résumé
- **WHEN** l'utilisateur choisit « Résumer »
- **THEN** le moteur choisi dans les réglages résume l'article et le résumé s'affiche en haut de l'article

#### Scenario: Résumer un article complet
- **GIVEN** le texte intégral de l'article a été chargé
- **WHEN** l'utilisateur choisit « Résumer »
- **THEN** le résumé porte sur le texte intégral, pas sur l'extrait du flux

#### Scenario: Article sans contenu
- **WHEN** l'article affiché n'a ni contenu fourni par le flux ni texte intégral
- **THEN** l'action « Résumer » est indisponible

#### Scenario: Aucun résumé automatique
- **WHEN** l'utilisateur affiche un article sans choisir « Résumer »
- **THEN** aucun moteur d'IA n'est sollicité pour cet article

#### Scenario: Résumer avec un moteur Claude
- **GIVEN** le moteur choisi est Claude Code ou Claude (API)
- **WHEN** l'utilisateur choisit « Résumer »
- **THEN** le résumé est rédigé par Claude et l'encadré affiche le nom de ce moteur

#### Scenario: Résumé dans la langue de l'interface
- **GIVEN** l'interface est en anglais
- **WHEN** l'utilisateur choisit « Summarize » sur un article écrit en français
- **THEN** le moteur reçoit la consigne de résumer en anglais
