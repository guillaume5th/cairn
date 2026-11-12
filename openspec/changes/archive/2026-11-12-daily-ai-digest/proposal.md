# Proposal

## Why

Avec plusieurs dizaines d'articles par jour, survoler la liste prend du temps. Un résumé quotidien rédigé par une IA, prêt chaque jour à l'heure choisie, donne l'essentiel des nouveautés d'un coup d'œil, sans quitter Cairn et sans envoyer les articles à un service distant.

## What Changes

- Nouveau résumé quotidien : chaque jour, à une heure réglable (8 h par défaut), Cairn rafraîchit les abonnements puis fait résumer par une IA locale les articles publiés dans les 24 heures précédentes.
- Deux moteurs au choix, tous deux locaux : Apple Foundation Models (sur l'appareil, par défaut) ou Ollama (serveur local, URL et modèle réglables).
- Rattrapage : si l'app était fermée à l'heure prévue, le résumé est produit au lancement suivant. Pas de processus en arrière-plan quand l'app est fermée.
- Nouvelle entrée « Résumés » dans la barre latérale : la liste des résumés, du plus récent au plus ancien ; chaque résumé montre son texte et les liens vers les articles résumés.
- Commande « Générer le résumé maintenant » pour relancer à la main (après un échec, par exemple).
- Conservation : les résumés de plus de N jours sont supprimés ; N vaut 7 par défaut et se règle.
- Nouvelle fenêtre Réglages (⌘,) pour l'heure, le moteur, Ollama et la durée de conservation.

## Capabilities

### New Capabilities
- `daily-digest` : production planifiée du résumé quotidien par IA locale, choix du moteur, affichage, régénération manuelle et conservation des résumés.

### Modified Capabilities
_Aucune._ La purge des articles (30 jours) et le rafraîchissement ne changent pas ; le résumé réutilise le rafraîchissement existant.

## Impact

- `CairnCore` : nouveau modèle SwiftData `Digest` (ajouté au `ModelContainer`), sélection des articles du jour, construction du prompt, purge des résumés, protocole de moteur avec implémentations Apple (framework `FoundationModels`) et Ollama (`URLSession`, API HTTP `/api/generate`). Aucune nouvelle dépendance.
- App : planification dans `AppState`, scène `Settings`, entrée `SidebarItem.digests` et vue de résumé, commande de menu.
- Réseau : appels HTTP vers `localhost` pour Ollama (entitlement `network.client` déjà présent ; exception ATS de réseau local à vérifier).
- Réglages stockés par Mac (`UserDefaults`), comme la taille du texte.
