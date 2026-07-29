# Plan: 2026-07-29 — Chromecast TV, Clean State & Échange Réseau Réactif
Statut: ✅ Terminé (Implémenté par OpenCode le 2026-07-29)

## Contexte
Suite aux retours de Ravimpotsy, deux évolutions sont prioritaires pour l'application Cuisine (Lakozia) :
1. **Affichage déporté Chromecast / Google Cast** : Streamer la vue Kanban vers un écran Android TV fixé en cuisine.
2. **Interface vierge (Clean State)** : Exporter les 12 commandes mock actuelles dans un fichier de démo et démarrer le Kanban vide par défaut pour faciliter les tests avec de vraies commandes.
3. **Préparer le répertoire `inbox/`** : Connecter le dossier d'entrée surveillé par le futur service de synchronisation pour recevoir les nouvelles commandes en temps réel depuis l'app Serveur.

## Tâches

### Phase 1 : Export des Données de Démo & Clean State
- [ ] Créer le répertoire `assets/samples/`
- [ ] Générer `assets/samples/kitchen_demo_orders.json` contenant les 12 commandes fictives actuelles
- [ ] Modifier le `KitchenProvider` (ou équivalent Riverpod) pour démarrer avec une liste vide par défaut
- [ ] Ajouter un bouton *"Charger données de démo"* dans l'onglet de configuration pour restaurer les 12 commandes de test

### Phase 2 : Déport d'Affichage Chromecast / Google Cast
- [ ] Ajouter les dépendances `cast` ou `flutter_cast_framework` dans `pubspec.yaml`
- [ ] Créer `lib/services/cast_service.dart` — Initialisation du Cast SDK, découverte des appareils Cast disponibles
- [ ] Créer `lib/ui/widgets/cast_button_widget.dart` — Bouton Cast overlay dans l'appbar du Kanban
- [ ] Créer `lib/ui/screens/cast_kanban_receiver.dart` — Vue épurée du Kanban optimisée pour affichage TV (grande police, fort contraste)
- [ ] Intégrer le maintien d'écran actif via `wakelock_plus` pendant l'affichage Kanban ou Cast

### Phase 3 : Dossier d'Échange Réactif (Inbox pour le Service de Sync)
- [ ] Créer `lib/services/sync_inbox_watcher.dart` — FileWatcher sur `sync_queue/inbox/` via `Directory.watch()` (événements `inotify` natifs)
- [ ] À chaque nouveau fichier détecté : parser l'événement JSON et injecter la commande dans le `KitchenProvider` Riverpod
- [ ] Déplacer le fichier traité vers `sync_queue/inbox/processed/` pour éviter les doublons

## Fichiers Concernés
| Action | Fichier |
|:---|:---|
| [NEW] | `assets/samples/kitchen_demo_orders.json` |
| [NEW] | `lib/services/cast_service.dart` |
| [NEW] | `lib/services/sync_inbox_watcher.dart` |
| [NEW] | `lib/ui/widgets/cast_button_widget.dart` |
| [NEW] | `lib/ui/screens/cast_kanban_receiver.dart` |
| [MODIFY] | `pubspec.yaml` — Ajout de `wakelock_plus`, dépendance Cast SDK |
| [MODIFY] | `lib/providers/kitchen_provider.dart` (ou équivalent) — État initial vide + méthode `loadDemoOrders()` |

## Notes Techniques
- **Cast SDK Flutter** : Vérifier la disponibilité d'un wrapper Flutter natif pour Google Cast. Si non disponible, utiliser un `MethodChannel` vers le SDK Cast natif Android.
- **`inotify` / `Directory.watch()`** : Fonctionne nativement sur Android. Le dossier `sync_queue/inbox/` doit être dans un répertoire accessible en écriture par les deux apps (ex: répertoire de stockage externe partagé ou Content Provider Android).
