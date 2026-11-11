# Design

## Context

- La recherche (`Library.search`) filtre avec `localizedStandardContains` sur le titre, le contenu HTML brut, la note et les noms de tags. Le texte recherché vit dans `ContentView` (`searchText`) et n'est pas transmis au panneau de lecture.
- Le contenu est rendu par `HTMLView` (`WebPage`) avec `allowsContentJavaScript = false`. La documentation de WebKit confirme que ce réglage bloque les scripts du contenu, pas ceux que l'application exécute via `callJavaScript`.
- Les lignes de la liste affichent le titre (2 lignes max) puis une ligne source/date.

## Goals / Non-Goals

**Goals :** même règle de correspondance partout ; extraits calculés en Swift et testés ; aucun script de l'article réactivé.

**Non-Goals :**
- Navigation entre occurrences (⌘G).
- Surlignage dans l'éditeur de note et de tags.
- Rechercher dans le texte rendu plutôt que dans le HTML brut (comportement actuel inchangé).

## Decisions

### Correspondance : `range(of:options: [.caseInsensitive, .diacriticInsensitive])`
Utilisé pour trouver les occurrences dans le titre et pour l'extrait. C'est la même règle que `localizedStandardContains` pour les textes concernés, et elle donne les positions, ce que `localizedStandardContains` ne fait pas.

### Extrait : `Library.snippet(for:in:)` dans CairnCore
Si le titre contient le terme, pas d'extrait. Sinon, première occurrence dans la note, puis les tags, puis le contenu réduit en texte (balises retirées, entités courantes décodées, espaces normalisés). Retourne ~40 caractères avant et ~80 après, coupés sur une espace, avec « … » aux coupures. Testé dans `LibraryTests` (titre, note, tag, contenu HTML, accents, coupure).
- *Alternative : texte rendu via `NSAttributedString(html:)`.* Écartée : lent, sur le fil principal, appelé pour chaque ligne à chaque frappe.

### Surlignage dans SwiftUI : `AttributedString`
Le titre de la ligne, l'extrait et le titre de l'article reçoivent un fond jaune sur chaque occurrence (`Color.yellow.opacity(0.45)`, texte inchangé), lisible aussi sur une ligne sélectionnée bleue.

### Surlignage du contenu : script de l'application
Après chaque chargement, et quand le terme change, `HTMLView` appelle `callJavaScript` avec le terme en argument. Le script retire les `<mark>` précédents, parcourt les nœuds texte (`TreeWalker`), compare une version repliée (`normalize('NFD')`, diacritiques retirés, minuscules) en gardant la correspondance des positions avec le texte d'origine, enveloppe chaque occurrence dans `<mark>`, puis fait défiler la première au centre. Le CSS de la page style `mark` comme le surlignage SwiftUI.
- *Alternative : insérer les `<mark>` dans le HTML côté Swift.* Écartée : un mot coupé par une balise ou écrit en entité (`&eacute;`) ne serait pas trouvé, et modifier le HTML hors des nœuds texte risque de casser des attributs.
- *Alternative : `find` de WebKit.* Écartée : ne surligne que l'occurrence courante.

### Transmission du terme
`ContentView` passe `searchText` à `ArticleDetailView`, puis à `HTMLView`. Un terme vide retire les surlignages sans recharger la page.

## Risks / Trade-offs

- [La recherche porte sur le HTML brut : un article peut être trouvé par un mot présent seulement dans le balisage, sans rien à surligner] → Comportement de recherche existant ; l'extrait sera alors vide, la ligne reste comme aujourd'hui.
- [Le script modifie le DOM à chaque frappe] → Coût négligeable pour un article ; les anciens `<mark>` sont retirés avant chaque passage.
- [Le décodage des entités de l'extrait ne couvre que les plus courantes] → Un extrait peut montrer une entité rare telle quelle ; sans effet sur la correspondance.
