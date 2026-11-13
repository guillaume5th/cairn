# Spec Delta

## ADDED Requirements

### Requirement: Activer ou désactiver le résumé automatique
Le système SHALL proposer dans la section Résumé quotidien des Réglages un interrupteur « Résumé automatique », activé par défaut et conservé sur ce Mac entre les lancements. Désactivé, le système MUST NOT produire de résumé automatiquement ; la génération à la demande, l'entrée « Résumés quotidiens » et les résumés déjà produits restent disponibles.

#### Scenario: Désactiver
- **GIVEN** l'interrupteur « Résumé automatique » est désactivé et l'heure du résumé est 8 h
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** aucun résumé n'est produit et aucune notification n'est envoyée

#### Scenario: Générer à la demande
- **GIVEN** l'interrupteur « Résumé automatique » est désactivé
- **WHEN** l'utilisateur clique sur « Générer un résumé »
- **THEN** un résumé est produit comme d'habitude

#### Scenario: Réactiver après l'heure
- **GIVEN** l'interrupteur est désactivé, l'heure du résumé est 8 h et aucun résumé n'a été tenté aujourd'hui
- **WHEN** l'utilisateur l'active à 10 h
- **THEN** le résumé d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Réglages grisés
- **WHEN** l'utilisateur désactive l'interrupteur
- **THEN** l'heure du résumé et « Me prévenir quand le résumé est prêt » sont grisés, et la durée de conservation reste modifiable

## MODIFIED Requirements

### Requirement: Heure du résumé quotidien
Le système SHALL, quand le résumé automatique est activé, produire un résumé par jour à l'heure réglée par l'utilisateur, 8 h par défaut. Le réglage MUST être conservé sur ce Mac entre les lancements. Le résumé est produit tant que l'app tourne, même sans fenêtre ouverte ; aucun processus ne tourne quand elle est quittée.

#### Scenario: Heure atteinte app ouverte
- **GIVEN** l'heure du résumé est 8 h et aucun résumé n'a encore été tenté aujourd'hui
- **WHEN** l'app est ouverte et il devient 8 h
- **THEN** un résumé est produit dans la minute

#### Scenario: Heure atteinte sans fenêtre
- **GIVEN** l'heure du résumé est 8 h, aucun résumé n'a encore été tenté aujourd'hui, et la fenêtre a été fermée sans quitter l'app
- **WHEN** il devient 8 h
- **THEN** un résumé est produit dans la minute et apparaît à la réouverture de la fenêtre

#### Scenario: Changement de l'heure
- **GIVEN** le résumé d'aujourd'hui n'a pas encore été tenté
- **WHEN** l'utilisateur règle l'heure sur un moment déjà passé aujourd'hui
- **THEN** le résumé d'aujourd'hui est produit sans attendre le lendemain

#### Scenario: Une seule tentative automatique par jour
- **GIVEN** le résumé d'aujourd'hui a déjà été tenté, avec succès ou non
- **WHEN** l'app reste ouverte le reste de la journée
- **THEN** aucun autre résumé automatique n'est lancé avant le lendemain

### Requirement: Rattrapage au lancement
Le système SHALL, quand le résumé automatique est activé, produire au lancement le résumé du jour quand l'heure réglée est passée et qu'aucun résumé n'a été tenté depuis.

#### Scenario: App fermée à l'heure prévue
- **GIVEN** l'heure du résumé est 8 h et l'app était fermée à 8 h
- **WHEN** l'utilisateur lance l'app à 10 h
- **THEN** un résumé est produit après le rafraîchissement du lancement

#### Scenario: Lancement avant l'heure
- **WHEN** l'utilisateur lance l'app à 7 h avec l'heure réglée à 8 h
- **THEN** aucun résumé n'est produit au lancement

#### Scenario: Plusieurs jours manqués
- **GIVEN** l'app est restée fermée trois jours
- **WHEN** l'utilisateur la lance après l'heure du résumé
- **THEN** un seul résumé est produit, celui du jour

#### Scenario: Résumé automatique désactivé
- **GIVEN** le résumé automatique est désactivé et l'app était fermée à l'heure du résumé
- **WHEN** l'utilisateur lance l'app après cette heure
- **THEN** aucun résumé n'est produit au lancement

### Requirement: Afficher les résumés
Le système SHALL afficher, quand l'utilisateur sélectionne l'entrée « Résumés quotidiens » de la barre latérale, la liste des résumés du plus récent au plus ancien, chacun désigné par sa date et son heure ; le résumé sélectionné s'affiche dans le volet de lecture.

#### Scenario: Ouvrir un résumé
- **WHEN** l'utilisateur sélectionne l'entrée « Résumés quotidiens » puis un résumé
- **THEN** son texte et la liste de ses articles s'affichent dans le volet de lecture

#### Scenario: Aucun résumé
- **WHEN** l'utilisateur sélectionne l'entrée « Résumés quotidiens » alors qu'il n'y a aucun résumé
- **THEN** la liste est vide et le volet indique l'heure du prochain résumé, ou que le résumé automatique est désactivé

### Requirement: Réglages du résumé
Le système SHALL offrir une fenêtre Réglages (⌘,) qui permet d'activer ou de désactiver le résumé automatique et de régler l'heure du résumé, le moteur, l'adresse et le modèle Ollama, et la durée de conservation. Les réglages Ollama MUST n'être affichés que lorsque le moteur Ollama est choisi.

#### Scenario: Choisir Ollama
- **WHEN** l'utilisateur choisit le moteur Ollama dans les Réglages
- **THEN** les champs adresse et modèle apparaissent, et le prochain résumé utilise Ollama
