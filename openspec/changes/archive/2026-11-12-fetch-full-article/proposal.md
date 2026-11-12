# Proposal

## Why

Beaucoup de flux ne fournissent qu'un court extrait de chaque article. Il faut alors ouvrir le navigateur pour lire la suite, et les résumés IA ne portent que sur l'extrait : l'encadré l'indique, mais le résumé reste pauvre. Récupérer la page de l'article et en extraire le contenu principal donne une vraie lecture dans Cairn et de meilleurs résumés.

## What Changes

- Action « Charger l'article complet » dans le panneau de lecture : Cairn télécharge la page de l'article, en extrait le texte principal (sans menus, publicités ni commentaires) et l'affiche à la place de l'extrait.
- Le texte intégral est conservé avec l'article, comme le contenu du flux, et peut être réaffiché sans nouveau téléchargement. Une commande permet de revenir au contenu fourni par le flux.
- Option par abonnement « Toujours charger l'article complet » : le texte intégral des nouveaux articles de cet abonnement est récupéré au rafraîchissement.
- Les résumés d'article et le résumé quotidien utilisent le texte intégral quand il est disponible.
- Mac, iPhone et iPad.

## Capabilities

### New Capabilities

- `full-article` : récupération, affichage et conservation du texte intégral d'un article à partir de sa page web, à la demande ou automatiquement par abonnement.

### Modified Capabilities

- `article-summary` : le résumé d'un article porte sur le texte intégral quand il est chargé, et l'encadré ne mentionne l'extrait que lorsque le résumé porte sur l'extrait.

## Impact

- **CairnCore :**
  - modèle `Article`, avec le texte intégral et sa date de récupération ;
  - modèle `Feed`, avec l'option par abonnement ;
  - `Library`, pour les prompts et le rafraîchissement ;
  - extraction du contenu (nouveau module).
- **App :**
  - `ArticleDetailView` : action, bascule et état de chargement ;
  - menu contextuel des abonnements dans `SidebarView` ;
  - `AppState`, pour le chargement.
- **Ressource embarquée :** Readability.js de Mozilla (licence Apache 2.0), exécuté par WebKit.
- **Données :** nouvelles propriétés optionnelles. La migration SwiftData est légère et automatique, et le schéma reste compatible CloudKit.
- **Confidentialité :** charger un article complet contacte le site de l'article, comme l'ouverture dans le navigateur, mais sans cookies ni exécution de script de la page.
