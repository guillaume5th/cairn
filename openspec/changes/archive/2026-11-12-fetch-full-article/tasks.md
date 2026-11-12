# Tasks

## 1. Extraction dans CairnCore

- [x] 1.1 Ajouter `Readability.js` (version épinglée de mozilla/readability) et sa licence en ressource du package CairnCore, et vérifier qu'il est chargé depuis `Bundle.module`
- [x] 1.2 Implémenter `ArticleExtractor.extract(from url:)` : téléchargement éphémère sans cookies (limite 5 Mo, 20 s), `WebPage` sans JavaScript de page, `callJavaScript` de Readability dans un monde isolé ; tests avec des pages enregistrées dans `Fixtures/` (blog, site d'actualité, page sans article → erreur « aucun contenu »)
- [x] 1.3 Ajouter `Article.fullContent`, `fullContentFetchedAt`, `showsFeedContent` et `Feed.loadsFullContentSince` ; vérifier qu'une base existante s'ouvre (base du simulateur créée par la version précédente du schéma, ouverte par la nouvelle)
- [x] 1.4 `Library.readableContent(_:)`, et l'utiliser dans `articleSummaryPrompt`, `digestPrompt` et `isExcerpt` ; tests dans LibraryTests (texte intégral prioritaire, retour au flux)

## 2. Lecture à la demande

- [x] 2.1 `AppState.loadFullContent(_:)` avec état « en cours » et erreur par article, sur le modèle de `summarize` ; vérifier qu'un changement d'article pendant le chargement range le texte au bon article
- [x] 2.2 Panneau de lecture : action « Charger l'article complet » (indisponible sans lien web), progression, message d'échec avec « Réessayer » et « Ouvrir dans le navigateur », bascule « Afficher le contenu du flux » / « Afficher l'article complet » ; vérifier sur Mac et sur le simulateur iPhone avec un flux à extraits
- [x] 2.3 Vérifier qu'une page avec scripts et iframes s'affiche sans les exécuter (fixture dédiée affichée dans l'app)

## 3. Mode automatique par abonnement

- [x] 3.1 Option « Toujours charger l'article complet » dans le menu contextuel d'un abonnement (case cochée), sur Mac et iOS
- [x] 3.2 Après `refreshAll`, charger le texte intégral des nouveaux articles des abonnements concernés (3 à la fois, tâche séparée) ; test : un rafraîchissement n'attend pas les chargements et un échec laisse le contenu du flux

## 4. Documentation et vérification

- [x] 4.1 README : mentionner l'article complet et le fait que le site est contacté (sans cookies) ; vérifier le rendu
- [x] 4.2 Résumer un article complet et vérifier que l'encadré ne parle plus d'extrait ; `openspec validate fetch-full-article --strict` passe

## Workflow follow-up

- Archiver le changement une fois la PR fusionnée, avec création de la spec `full-article` et synchronisation de `article-summary`.
