# Design

## Context

`HTMLView` affiche le contenu dans une `WebPage` avec JavaScript de la page désactivé et une CSP qui n'autorise que les images `https:` et `data:`. L'app exécute déjà ses propres scripts (surlignage, citations) dans le monde `.defaultClient` via `callJavaScript`, isolé des scripts de la page. La vue web ne donne pas l'URL d'une image sous le clic : `WebView.ActivatedElementInfo` n'expose que `linkURL` (vérifié contre le SDK macOS 27.2). Voir proposal.md pour la motivation.

## Goals / Non-Goals

**Goals:**
- Coup d'œil natif, sans affaiblir l'isolation du contenu des flux.

**Non-Goals:**
- Images hors du contenu affiché (icône du flux, lecteur vidéo), images `http:` (déjà bloquées par la CSP).

## Decisions

- **Détection du clic par un script de l'app, injecté après chaque chargement** : l'écouteur de clics sur `img` (hors `a`) est exécuté par `page.callJavaScript` dans le monde `.defaultClient`, comme le surlignage, après chaque `page.load`. Il envoie à un `WKScriptMessageHandler` (enregistré dans le même monde sur le `userContentController` de la configuration) l'index de l'image cliquée et la liste des `currentSrc` des images de la page. La page elle-même reste sans JavaScript. Vérifié dans Cairn Dev : le message arrive. Un `WKUserScript` n'a pas été retenu : je n'ai pas pu établir s'il s'exécute quand `allowsContentJavaScript` est faux. Alternative écartée : un menu contextuel « Coup d'œil » (`webViewContextMenu`), impossible sans l'URL de l'image, et qui remplace tout le menu par défaut.
- **Adresses acceptées, en logique pure** : `Library.quickLookImages(_ sources:)` (CairnCore) garde les adresses `https:` et `data:image/…` dans l'ordre, sans doublon, au plus 50, et leur donne un nom de fichier sûr (`01.png`, l'extension tirée du type MIME ou de l'adresse, `img` sinon). Les adresses viennent du flux : jamais utilisées comme chemin.
- **Téléchargement avant affichage** : Coup d'œil n'affiche que des fichiers locaux. Les images sont téléchargées avec une session éphémère (sans cookies, comme `ArticleExtractor`), 20 Mo au plus chacune, l'image cliquée d'abord puis les autres, dans un dossier temporaire propre à la vue (`FileManager.temporaryDirectory/Cairn-QuickLook/<UUID>`). Une image qui échoue est omise.
- **Affichage par `.quickLookPreview($url, in: urls)`** de SwiftUI sur `HTMLView` : Coup d'œil s'ouvre sur l'image cliquée avec les autres en parcours. Alternative écartée : `QLPreviewPanel` piloté à la main, qui demande d'entrer dans la chaîne de répondeurs AppKit.
- **Nettoyage** : le dossier est effacé quand le contenu affiché change (nouvel article) et à la disparition de la vue ; `.quickLookPreview` se ferme quand son URL passe à nil.

## Risks / Trade-offs

- [Le gestionnaire de messages reçoit des données d'une page de flux] → seul le script de l'app, dans son propre monde, peut écrire sur ce canal ; le message est quand même validé (index dans les bornes, adresses filtrées par `quickLookImages`).
- [Images lourdes ou nombreuses] → limite de 50 images et 20 Mo par image ; l'image cliquée est téléchargée d'abord pour que Coup d'œil s'ouvre vite.
- [Images `srcset` ou chargées tardivement] → `currentSrc` donne la source réellement affichée.
- [Le clic dans la vue web pourrait aussi sélectionner du texte] → le script ne bloque pas l'événement, la sélection reste possible.
- [Une image dont la source change après le chargement (chargement différé) n'est pas vue par l'écouteur de clics] → l'écouteur lit `currentSrc` au moment du clic, pas au chargement.
