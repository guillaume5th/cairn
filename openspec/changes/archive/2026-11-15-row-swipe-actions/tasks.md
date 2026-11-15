# Tasks

## 1. Balayage

- [x] 1.1 `ContentView` : `.swipeActions(edge: .leading)` sur la ligne avec le bouton lu / non lu (mêmes libellés et symboles que le menu de l'article), sur l'article de la ligne seul ; vérifier dans Cairn Dev au trackpad que la sélection ne change pas et que le compteur de non lus suit
- [x] 1.2 `.swipeActions(edge: .trailing)` : `ReadLaterButton`, puis le bouton garder / retirer seulement pour un article gardé ou s'il n'existe qu'un cairn (bouton simple, jamais le menu des cairns, que le balayage ne peut pas ouvrir) ; retrait par `articlesToUnkeep` pour la confirmation ; vérifier dans Cairn Dev avec un et deux cairns, et le retrait d'un article annoté
- [x] 1.3 Couleurs des actions (lu : accent, Lire plus tard : orange, retirer : destructive) et `allowsFullSwipe` seulement pour lu / non lu ; vérifier que le balayage complet vers la gauche ne retire rien d'un cairn

## 2. Vérification

- [x] 2.1 Scénarios de la spec dans Cairn Dev, en mode sélection aussi (le balayage reste sans effet sur les cases cochées) ; `swift test` vert et `BUILD SUCCEEDED`
