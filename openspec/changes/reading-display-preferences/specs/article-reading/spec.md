# Spec Delta

## ADDED Requirements

### Requirement: Taille du texte de l'article
Le système SHALL permettre d'agrandir, de réduire et de rétablir la taille du texte du panneau de lecture depuis le menu Présentation (⌘+, ⌘−, ⌘0). La taille MUST s'appliquer au titre, à la ligne source et date et au contenu de l'article, rester entre un minimum et un maximum, et être conservée d'un lancement à l'autre.

#### Scenario: Agrandir le texte
- **WHEN** l'utilisateur choisit « Agrandir le texte » ou appuie sur ⌘+
- **THEN** le titre, la ligne source et date et le contenu de l'article affiché grandissent ensemble

#### Scenario: Taille normale
- **WHEN** l'utilisateur choisit « Taille normale » ou appuie sur ⌘0
- **THEN** le panneau de lecture revient à la taille par défaut

#### Scenario: Limite atteinte
- **WHEN** la taille maximale est atteinte
- **THEN** « Agrandir le texte » est indisponible et la taille ne change plus (et de même pour « Réduire le texte » au minimum)

#### Scenario: Changement d'article et relancement
- **WHEN** l'utilisateur a agrandi le texte puis affiche un autre article ou relance l'application
- **THEN** le nouvel article s'affiche avec la taille choisie
