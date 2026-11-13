# Tasks

## 1. Sélection d'article

- [x] 1.1 Dans `App/ContentView.swift`, faire renvoyer `nil` à `displayedArticleID` quand l'article mémorisé n'est pas dans la liste de l'entrée, et mettre à jour son commentaire
- [x] 1.2 Faire effacer par `settleArticle()` l'article mémorisé qui n'est plus visible au lieu de le remplacer par le premier, et mettre à jour son commentaire
- [x] 1.3 Vérifier que `xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build` réussit et que `cd CairnCore && swift test` passe

## 2. Vérification dans Cairn Dev

- [x] 2.1 Lancer « Cairn Dev » et vérifier : un abonnement jamais ouvert n'affiche aucun article (« Aucun article sélectionné », boutons grisés, barre d'outils immobile) ; un article choisi est retrouvé en revenant sur l'entrée et après relancement ; un article mémorisé caché par le filtre « Non lus » laisse le volet vide ; « Résumés quotidiens » affiche toujours le plus récent
