# Tasks

## 1. Modèle et prompt dans CairnCore

- [x] 1.1 Ajouter à `Article` les propriétés optionnelles `summary`, `summaryDate`, `summaryEngine` ; vérifier que l'app s'ouvre sur le store existant (migration légère) avec ses articles intacts (même nombre d'articles dans le store avant et après)
- [x] 1.2 Ajouter `Library.articleSummaryPrompt(for:)` (consignes, titre, texte brut coupé au budget de 6 000 caractères) et `Library.isExcerpt(_:)` (texte brut de moins de 500 caractères) ; vérifier par des tests : le prompt contient le titre et le texte sans balises HTML, ne dépasse pas le budget pour un contenu très long, et `isExcerpt` vaut vrai pour un extrait court et faux pour un article long

## 2. Génération

- [x] 2.1 Ajouter à `AppState` `summarizing`, `summaryErrors` et `summarize(_:)` (refus si déjà en cours, écriture sur l'article seulement en cas de succès, erreur gardée sinon) ; vérifier par un test avec un `Summarizer` factice si `AppState` est testable, sinon dans l'app à la tâche 3.2

## 3. Interface

- [x] 3.1 Sortir `markdownLine` de `DigestView` en fonction partagée, sans changer le rendu des résumés quotidiens ; vérifier dans l'app qu'un résumé quotidien s'affiche comme avant (intertitres et puces)
- [x] 3.2 Ajouter le bouton « Résumer » / « Régénérer le résumé » à la barre d'outils d'`ArticleDetailView` et l'encadré du résumé (en-tête date · moteur, Régénérer, progression, erreur, mention de l'extrait, hauteur bornée) ; vérifier dans l'app avec Ollama : un article est résumé, changer d'article pendant la génération puis revenir montre le résumé sur le bon article, le bouton est désactivé sur un article sans contenu, et la position des boutons de la liste ne bouge pas entre un article, une sélection multiple et un résumé quotidien
- [x] 3.3 Vérifier dans l'app l'échec et la conservation : avec une adresse Ollama erronée, « Régénérer » affiche l'erreur dans l'encadré et garde le résumé précédent ; après relance de l'app, le résumé de l'article est affiché sans nouvel appel (adresse Ollama erronée toujours en place, aucune erreur)
- [x] 3.4 Ajouter le pied de la section « Moteur d'IA » des réglages (moteur utilisé pour les résumés quotidiens et les résumés d'articles) ; vérifier dans la fenêtre des réglages

## 4. Intégration

- [x] 4.1 Lancer `swift test` et compiler l'app ; vérifier que tout passe, puis remettre l'adresse Ollama d'origine et retirer les résumés d'articles créés pour les tests

## 5. Retours

- [x] 5.1 Supprimer et masquer le résumé d'un article (masquage conservé d'un article à l'autre) ; vérifié dans l'app : masquer réduit l'encadré à son en-tête et reste actif sur l'article suivant, supprimer efface le résumé du store et rend « Résumer »
- [x] 5.2 Afficher les listes Markdown en puces (avec retrait par niveau) dans les résumés d'articles et quotidiens ; vérifié dans l'app sur un résumé Apple Intelligence
- [x] 5.3 Tester avec Apple Intelligence ; vérifié : résumé produit, moteur « Apple » affiché

## Workflow follow-up

- Archiver le change une fois validé (`/opsx:archive`).
