# Proposal

## Why

Le résumé quotidien donne une vue d'ensemble de la journée. Mais devant un article long, il faut encore le lire en entier pour savoir s'il vaut la peine. Cairn sait déjà faire résumer du texte par une IA locale (Apple Intelligence ou Ollama) : il peut le faire aussi pour l'article qu'on lit, à la demande.

## What Changes

- Un bouton « Résumer » dans la barre d'outils de l'article fait résumer l'article affiché, avec le moteur choisi dans les réglages des résumés quotidiens.
- Le résumé s'affiche dans un encadré en haut de l'article, avec sa date et le moteur utilisé. L'encadré montre une progression pendant la génération et un message en cas d'échec. Un bouton « Régénérer » refait le résumé.
- La source est le contenu fourni par le flux. Quand ce contenu est court (un simple extrait), l'encadré l'indique (« Résumé de l'extrait fourni par le flux »).
- Le résumé est conservé avec l'article : revenir sur l'article ne relance pas l'IA. Il suit l'article : gardé avec lui dans un cairn, supprimé avec lui à la purge.
- Hors périmètre : rechercher dans ces résumés, résumer plusieurs articles sélectionnés, résumer automatiquement, aller chercher la page complète sur le site.

## Capabilities

### New Capabilities
- `article-summary` : résumé à la demande d'un article par l'IA locale, son affichage dans le volet de lecture et sa conservation avec l'article.

### Modified Capabilities
_Aucune._ Le moteur et ses réglages restent ceux de `daily-digest`, sans changement d'exigence. L'affichage d'un article (`article-reading`) ne change pas : l'encadré s'ajoute au-dessus du contenu.

## Impact

- `CairnCore` : un champ optionnel sur `Article` (texte, date et moteur du résumé), ajout léger sans migration manuelle ; une fonction qui construit le prompt d'un article (texte brut du contenu, borné pour le modèle d'Apple), testée sans UI.
- App : bouton « Résumer » et encadré du résumé dans `ArticleDetailView`, réutilisant `DigestSettings.summarizer()`.
- Aucune nouvelle dépendance.
