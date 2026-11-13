# Tasks

## 1. Réglage et planification

- [x] 1.1 Ajouter à `DigestSettings` la clé `digestEnabled` (vraie par défaut) et faire renvoyer faux à `isDue` quand elle est fausse ; vérifier dans Cairn Dev qu'avec le réglage désactivé et une heure déjà passée sans tentative aujourd'hui, aucun résumé n'est produit dans la minute ni au lancement
- [x] 1.2 Vérifier que « Générer un résumé » produit encore un résumé quand le réglage est désactivé
- [x] 1.3 Vérifier qu'en réactivant le réglage après l'heure, sans tentative ce jour-là, le résumé du jour est produit dans la minute

## 2. Interface

- [x] 2.1 Ajouter l'interrupteur « Résumé automatique » en tête de la section Résumé quotidien de `SettingsView`, griser l'heure et « Me prévenir quand le résumé est prêt » quand il est désactivé, adapter le pied de section ; vérifier sur capture que la fenêtre garde sa hauteur et que la conservation reste modifiable
- [x] 2.2 Afficher « Résumé automatique désactivé. » dans le volet sans résumé (`DigestDetail`) quand le réglage est désactivé, et vérifier sur capture

## 3. Intégration

- [x] 3.1 Construire l'app (`xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build`) et vérifier `BUILD SUCCEEDED`
