# Proposal

## Why

Le résumé quotidien est produit automatiquement chaque jour, sans moyen de l'arrêter : un utilisateur qui ne s'en sert pas paie quand même un appel au moteur d'IA par jour, local ou Ollama, et voit sa liste de résumés se remplir.

## What Changes

- Un interrupteur « Résumé automatique » dans la section Résumé quotidien des Réglages, activé par défaut (comportement actuel).
- Désactivé : aucun résumé n'est produit automatiquement, ni à l'heure réglée, ni en rattrapage au lancement, donc aucune notification « résumé prêt ».
- Inchangé quand il est désactivé : la génération à la demande (bouton « Générer un résumé », menu « Générer le résumé maintenant »), l'entrée « Résumés quotidiens » de la barre latérale, les résumés déjà produits et leur conservation.
- Désactivé, l'heure du résumé et l'interrupteur de notification sont grisés dans les Réglages, et le volet des résumés vides n'annonce plus d'heure de prochain résumé.
- Réactivé après l'heure réglée, sans tentative ce jour-là, le résumé du jour est produit tout de suite, comme quand on avance l'heure.

## Capabilities

### New Capabilities

Aucune.

### Modified Capabilities

- `daily-digest` : nouvel interrupteur du résumé automatique ; l'heure réglée et le rattrapage au lancement ne s'appliquent que lorsqu'il est activé ; Réglages et volet sans résumé reflètent son état.

## Impact

- `App/DigestViews.swift` : clé et valeur par défaut du réglage (`DigestSettings`), interrupteur et grisage dans `SettingsView`, texte du volet vide (`DigestDetail`).
- `App/AppState.swift` : aucune modification attendue, la boucle de planification passant par `DigestSettings.isDue`.
- Aucun impact sur `CairnCore`, les données ni la génération manuelle.
