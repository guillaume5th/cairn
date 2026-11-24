# Proposal

## Why

Avant d'ouvrir un article, on ne sait pas s'il se lit en une minute ou en un quart d'heure : il faut le survoler pour décider de le lire maintenant ou de le garder pour plus tard. Une durée estimée, visible dans la liste et dans l'en-tête, aide à trier d'un coup d'œil.

## What Changes

- L'en-tête de l'article affiche, après la source et la date, le temps de lecture estimé (« · 14 min read »).
- Chaque ligne de la liste affiche, à côté du nom de la source, une icône de chronomètre et la durée (« 14 min ») ; la date relative reste seule à droite, pour que les deux nombres ne se confondent pas.
- La durée est calculée depuis le texte lisible de l'article (texte intégral s'il est chargé, sinon contenu du flux), à 230 mots par minute, arrondie à la minute, au moins 1 minute. Un article sans texte n'affiche rien.
- Libellé localisé en français et en anglais.

## Capabilities

### New Capabilities

### Modified Capabilities
- `article-reading`: ajout d'une exigence « Temps de lecture estimé ».

## Impact

- `CairnCore/Sources/CairnCore/Library.swift` : `Library.readingMinutes(_:)`, un seul passage sur les octets du HTML, sans allocation ; il est appelé à chaque rendu de ligne.
- `App/ContentView.swift` (ligne de liste), `App/ArticleDetailView.swift` (en-tête), `App/Localizable.xcstrings` (« %lld min read »).
- `CairnCore/Tests/CairnCoreTests/DigestTests.swift` : un test du calcul.
- Aucune dépendance ajoutée, aucun changement du modèle de données.
- Hors périmètre : vitesse de lecture réglable, estimation propre aux écritures sans espaces (chinois, japonais), mise en cache du résultat.
