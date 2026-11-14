## ADDED Requirements

### Requirement: Doublons entre abonnements
Le système SHALL créer comme lu un nouvel article dont le lien, une fois normalisé, est déjà celui d'un article existant d'un autre abonnement. La normalisation MUST ignorer le schéma http/https, la casse de l'hôte, un préfixe `www.`, le fragment, la barre oblique finale et les paramètres `utm_*`. Un article sans lien MUST NOT être considéré comme un doublon.

#### Scenario: Même article via deux abonnements
- **GIVEN** l'abonnement « Blog » contient un article non lu de lien `https://exemple.fr/post`
- **WHEN** l'abonnement « Agrégateur » reçoit un article de lien `http://www.exemple.fr/post/?utm_source=rss`
- **THEN** cet article est enregistré dans « Agrégateur », déjà lu, et le nombre de non lus de « Tous les articles » ne change pas

#### Scenario: Doublons dans un même rafraîchissement
- **WHEN** deux abonnements apportent le même lien inconnu lors du même rafraîchissement
- **THEN** le premier article enregistré est non lu et le second est lu

#### Scenario: Article sans lien
- **WHEN** deux abonnements apportent chacun un article sans lien
- **THEN** les deux sont enregistrés non lus
