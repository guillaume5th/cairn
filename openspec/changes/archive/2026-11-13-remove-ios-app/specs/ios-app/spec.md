# Spec Delta

## REMOVED Requirements

### Requirement: Application universelle iPhone et iPad
**Reason**: Cairn se concentre sur l'app Mac ; l'app iOS exige un compte Apple Developer payant pour un usage durable.
**Migration**: Utiliser l'app Mac. Les abonnements restent exportables en OPML (Fichier > Exporter OPML…).

### Requirement: Données propres à l'appareil
**Reason**: Plus d'app iOS, donc plus de bibliothèque par appareil à distinguer.
**Migration**: Aucune ; la bibliothèque du Mac n'est pas touchée.

### Requirement: Mise en page selon l'appareil
**Reason**: Plus d'iPhone ni d'iPad à mettre en page.
**Migration**: Aucune.

### Requirement: Retour à la liste après « non lu » sur iPhone
**Reason**: Comportement propre à la largeur compacte de l'iPhone.
**Migration**: Aucune ; sur Mac l'article reste affiché.

### Requirement: Commandes accessibles sans barre des menus
**Reason**: Le Mac garde ces commandes dans la barre des menus.
**Migration**: Aucune.

### Requirement: Raccourcis clavier sur iPad
**Reason**: Plus d'app iPad ; les raccourcis restent sur Mac.
**Migration**: Aucune.

### Requirement: Réglages sur iOS
**Reason**: Les Réglages du Mac restent la seule présentation.
**Migration**: Aucune.

### Requirement: Cycle de vie sur iOS
**Reason**: Le cycle de vie du Mac est couvert par `app-lifecycle`.
**Migration**: Aucune.

### Requirement: Moteur Ollama sur le réseau local
**Reason**: Propre à l'accès réseau local d'iOS ; sur Mac, l'adresse Ollama reste réglable.
**Migration**: Aucune.

### Requirement: Rafraîchissement en arrière-plan sur iOS
**Reason**: Tâches d'arrière-plan iOS retirées ; le Mac rafraîchit tant que l'app tourne.
**Migration**: Aucune.

### Requirement: Résumé quotidien en arrière-plan sur iOS
**Reason**: Tâches d'arrière-plan iOS retirées ; le résumé en arrière-plan du Mac (fenêtre fermée) est inchangé.
**Migration**: Aucune.
