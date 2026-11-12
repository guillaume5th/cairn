# Spec Delta

## ADDED Requirements

### Requirement: Supprimer plusieurs résumés
Le système SHALL permettre de sélectionner plusieurs résumés (⌘-clic, ⇧-clic, ⌘A) et de les supprimer d'un coup, par le menu contextuel, la touche Supprimer ou la corbeille, après une seule confirmation qui indique leur nombre. Quand plusieurs résumés sont sélectionnés, le volet de lecture MUST afficher « N résumés sélectionnés » au lieu d'un résumé.

#### Scenario: Supprimer trois résumés
- **GIVEN** trois résumés sont sélectionnés
- **WHEN** l'utilisateur appuie sur Supprimer puis confirme « Supprimer 3 résumés ? »
- **THEN** les trois résumés sont supprimés et le plus récent des résumés restants s'affiche

#### Scenario: Volet de lecture
- **WHEN** l'utilisateur sélectionne deux résumés
- **THEN** le volet de lecture affiche « 2 résumés sélectionnés » et la corbeille supprime les deux
