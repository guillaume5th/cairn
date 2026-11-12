# Design

## Context

Voir proposal.md (Why) et `specs/article-summary/spec.md`. État actuel, observé dans le code :

- `Summarizer` (CairnCore) a deux implémentations, `AppleSummarizer` (FoundationModels, une `LanguageModelSession` par appel) et `OllamaSummarizer` (`POST /api/generate`, délai de 300 s). Leurs erreurs sont déjà des messages en français (`CairnError.summarizerUnavailable`, serveur injoignable, modèle absent).
- `DigestSettings.summarizer()` (App) renvoie le moteur choisi et son nom affiché (« Apple » ou « Ollama (modèle) »). Les réglages ont une section « Moteur d'IA » distincte de la section « Résumé quotidien ».
- `Library.digestPrompt(for:)` borne le prompt à 6 000 caractères (`digestPromptBudget`) pour tenir dans les 4 096 tokens du modèle d'Apple, et `Library.plainText(_:)` extrait le texte d'un contenu HTML.
- `AppState.makeDigest` porte l'état de génération du résumé quotidien (`isDigesting`) et son message d'erreur (`message`, affiché en alerte).
- `ArticleDetailView` affiche l'en-tête (titre, source, date), un `Divider`, puis `HTMLView` (ou « Aucun contenu »), et sa barre d'outils (`KeepButton`, « Marquer comme non lu », « Ouvrir dans le navigateur »).
- `DigestView.markdownLine(_:)` (privée) rend le Markdown d'un résumé ligne par ligne (intertitres en gras, Markdown en ligne).
- `Library.ingest` ne réécrit jamais un article déjà connu : son contenu ne change pas après sa première ingestion.

## Goals / Non-Goals

**Goals:**
- Réutiliser les moteurs, les réglages et le rendu Markdown du résumé quotidien ; aucune nouvelle dépendance.
- Une génération qui survit au changement d'article et ne bloque pas la lecture.

**Non-Goals:**
- Télécharger la page de l'article, résumer plusieurs articles, résumer automatiquement, chercher dans les résumés.
- Annuler une génération en cours.

## Decisions

**Résumé stocké sur `Article`.** Trois propriétés optionnelles : `summary: String?`, `summaryDate: Date?`, `summaryEngine: String?`. Des propriétés optionnelles avec défaut sont une migration légère que SwiftData fait seul, et restent compatibles avec le schéma CloudKit (règles en tête de `Models.swift`). Le résumé suit l'article sans rien coder : purge et suppression l'emportent avec lui, un article gardé le garde. Comme `ingest` ne réécrit pas le contenu, le résumé ne peut pas devenir périmé.
Alternative écartée : un `@Model ArticleSummary` relié à l'article. Il faudrait une relation, une règle de suppression et une requête de plus pour un seul texte.

**Prompt dans CairnCore.** `Library.articleSummaryPrompt(for:)` : consignes (résumer en français, en Markdown, en quelques phrases ou puces, rester factuel, ne rien inventer), le titre, puis le texte brut du contenu (`plainText`) coupé pour que le prompt ne dépasse pas `digestPromptBudget`. `Library.isExcerpt(_:)` vaut vrai quand ce texte brut fait moins de 500 caractères : l'encadré affiche alors « Résumé de l'extrait fourni par le flux ». Les deux fonctions sont pures et testées sans moteur.

**État de génération dans `AppState`.** `summarizing: Set<PersistentIdentifier>` et `summaryErrors: [PersistentIdentifier: String]`, non persistés, et `func summarize(_ article: Article) async`. La méthode refuse un article déjà en cours, efface son erreur, appelle `DigestSettings.summarizer()` puis le moteur, et écrit `summary`, `summaryDate` et `summaryEngine` sur l'article seulement en cas de succès : un échec garde le résumé précédent et remplit `summaryErrors`. La vue lance la méthode dans un `Task` détaché de son cycle de vie (pas `.task`), pour que changer d'article n'annule pas la génération ; le résultat va à l'article d'origine, retrouvé par sa référence. Plusieurs articles peuvent être résumés en parallèle.
Alternative écartée : un état local dans `ArticleDetailView`. Il est perdu quand on change d'article, et le résultat ne pourrait plus être rattaché.
Contrairement au résumé quotidien, l'erreur s'affiche dans l'encadré et non en alerte : elle concerne un article précis et doit rester visible quand on y revient.

**Interface.**
- Barre d'outils : un bouton « Résumer » (`text.append`, l'icône des résumés quotidiens), après « Ouvrir dans le navigateur ». Il est désactivé sans contenu ou pendant la génération, et s'appelle « Régénérer le résumé » quand l'article en a un.
- Encadré : un `GroupBox` entre l'en-tête et le contenu, affiché seulement s'il y a un résumé, une génération ou une erreur. Il contient :
  - une ligne d'en-tête « Résumé · date · moteur » avec un bouton « Régénérer » sans bordure ;
  - le texte, rendu par le même code que les résumés quotidiens : `markdownLine` sort de `DigestView` en fonction partagée, appelée sans terme recherché ;
  - un `ProgressView` pendant la génération ;
  - l'erreur, s'il y en a une ;
  - la mention de l'extrait, quand le contenu du flux est court.
- La hauteur de l'encadré est bornée (défilement interne au-delà), pour que le contenu de l'article reste visible.
- Réglages : la section « Moteur d'IA » reçoit un pied de section qui précise que ce moteur sert aux résumés quotidiens et aux résumés d'articles.

## Risks / Trade-offs

- [Article long et modèle d'Apple limité à 4 096 tokens] → le texte est coupé au budget. Le résumé porte alors sur le début de l'article, comme le résumé quotidien qui coupe ses extraits. Acceptable pour une première version.
- [Contenu du flux réduit à un extrait] → le résumé n'apporte presque rien de plus que l'extrait. La mention le signale, et télécharger la page est hors périmètre.
- [Génération longue avec Ollama, jusqu'à 300 s] → la progression reste visible, la lecture n'est pas bloquée et on peut changer d'article. Il n'y a pas d'annulation.
- [Apple Intelligence et appels parallèles] → une session par appel. Un échec éventuel s'affiche comme les autres erreurs.

## Migration Plan

Migration légère automatique de SwiftData (trois propriétés optionnelles ajoutées à `Article`). Pas de retour arrière à prévoir : une version antérieure de l'app ignore ces colonnes.
