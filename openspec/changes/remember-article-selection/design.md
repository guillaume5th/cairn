# Design

## Context

- `ContentView` garde deux `@State` : `selection: SidebarItem?` (entrée, `.all` par défaut) et `selectedArticleID: PersistentIdentifier?`. `onChange(of: selection)` remet `selectedArticleID` à `nil`, d'où le panneau vide.
- La liste visible est calculée (`visibleArticles`) depuis l'entrée, le filtre « Non lus » et la recherche du cairn. Le panneau de lecture résout l'article dans **tous** les articles, pas seulement les visibles : un article qui sort de la liste (lu avec le filtre actif) reste affiché.
- `ArticleDetailView` marque lu via `.task(id: article.persistentModelID) { article.isRead = true }`, donc tout article affiché devient lu.
- Les modèles sont synchronisés par CloudKit. La sélection doit rester propre au Mac.

## Goals / Non-Goals

**Goals :**
- Distinguer la sélection faite par l'utilisateur de la sélection automatique, pour ne marquer lu que la première.
- Une seule source de vérité par entrée, persistée sans toucher au modèle SwiftData.

**Non-Goals :**
- Restaurer la position de défilement de la liste. Le `List` est déjà reconstruit à chaque arrivée d'articles (`.id(articles.count)`).
- Synchroniser la sélection entre appareils.
- Mémoriser l'état du filtre « Non lus » ou le texte de recherche.

## Decisions

### Mémoire : un dictionnaire par entrée dans `@AppStorage`
Une structure `Codable` contenant l'entrée courante (`SidebarItem`) et `[SidebarItem: PersistentIdentifier]`, encodée en JSON dans une seule clé UserDefaults, chargée dans un `@State` et réécrite à chaque changement (un `@AppStorage` de `Data` obligerait à décoder à chaque lecture dans `body`). `SidebarItem` devient `Codable` par synthèse (`PersistentIdentifier` est `Codable`).
- *Alternative : `@SceneStorage`.* Écartée : la restauration de scène dépend du réglage macOS « Fermer les fenêtres en quittant », ce qui rendrait la persistance aléatoire.
- *Alternative : champ sur le modèle SwiftData.* Écartée : ce champ serait synchronisé par CloudKit et nécessiterait une migration.
- Les identifiants mémorisés pour des entrées ou des articles supprimés restent dans le dictionnaire. Ils ne gênent pas, car chaque lecture vérifie que l'article existe. On ne les nettoie pas : le volume est négligeable.

### Résolution de l'article affiché
L'article affiché vaut l'article mémorisé de l'entrée s'il existe encore parmi tous les articles, sinon le premier de `visibleArticles`.
À chaque changement d'entrée et au lancement, si l'article mémorisé n'est pas dans `visibleArticles`, le premier article visible le remplace dans la mémoire. Ce remplacement compte comme une sélection automatique. On applique ainsi le repli quand on revient sur une entrée, sans faire sauter la sélection pendant la lecture : avec le filtre « Non lus », l'article que l'on vient de lire reste affiché, comme aujourd'hui.
- *Alternative : toujours retomber sur le premier article visible quand l'article mémorisé est masqué.* Écartée : avec le filtre « Non lus », lire un article le masquerait aussitôt, ce qui afficherait et rendrait lu le suivant, en cascade.

### Lu seulement au choix de l'utilisateur
Le binding passé au `List` des articles est construit à la main. Son `set`, que SwiftUI n'appelle que sur une action de l'utilisateur (souris ou clavier), écrit dans la mémoire et retient l'article choisi (`pickedID`). Changer d'entrée efface `pickedID`. `ArticleDetailView` reçoit `marksRead = (article affiché == pickedID)` et ne marque l'article lu dans sa `.task` que dans ce cas. Si l'article choisi disparaît (purge, suppression), l'article de repli ne correspond pas à `pickedID` et n'est donc pas marqué lu.
- *Alternative : un simple booléen levé par le `set`.* Écartée : le booléen resterait levé quand l'article choisi est supprimé, et l'article de repli serait alors marqué lu.

### Entrée disparue au relancement
Au lancement, une entrée `.feed` absente des abonnements ou `.tag` absente des tags portés par un article gardé est remplacée par `.all`. Cela demande une `@Query` des abonnements dans `ContentView`, la barre latérale ayant déjà la sienne. Pendant l'exécution, la suppression d'un abonnement remet déjà `.all` (`SidebarView`).

## Risks / Trade-offs

- [Un article sélectionné automatiquement puis recliqué n'est pas marqué lu : cliquer une ligne déjà sélectionnée ne déclenche pas le `set` du binding] → L'utilisateur peut le marquer lu en passant à un autre article puis en revenant, ou avec « Tout marquer comme lu ». C'est un écart limité et assumé.
- [Un `PersistentIdentifier` relu depuis le JSON est `==` à l'identifiant en mémoire mais n'a pas le même hash : il ne retrouve pas sa clé dans le dictionnaire, ce qui crée des doublons et fait perdre la mémoire après un redémarrage (constaté pendant les tests)] → Au lancement, chaque identifiant relu est remplacé par `context.model(for:).persistentModelID`.
- [Un `PersistentIdentifier` peut devenir invalide après une réinitialisation du store] → La résolution ne le trouve plus et retombe sur le premier article.
- [La liste est vide au lancement, avant le premier rafraîchissement] → La résolution est calculée : le premier article apparaît dès que les articles arrivent, sans être marqué lu.

## Migration Plan

Aucune migration : en l'absence de la clé `@AppStorage`, on part de « Tous les articles » sans mémoire. Pour revenir en arrière, il suffit de restaurer le code ; la clé orpheline est ignorée.
