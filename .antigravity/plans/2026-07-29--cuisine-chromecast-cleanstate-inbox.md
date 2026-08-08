# Plan: 2026-07-29 — Chromecast TV, Clean State & Échange Réseau Réactif
Statut: ✅ Terminé (Implémenté par OpenCode le 2026-07-29, complété le 2026-07-31 par l'implémentation native Android du canal Cast + nettoyage UI AppBar)

## Contexte
Suite aux retours de Ravimpotsy, deux évolutions sont prioritaires pour l'application Cuisine (Lakozia) :
1. **Affichage déporté Chromecast / Google Cast** : Streamer la vue Kanban vers un écran Android TV fixé en cuisine.
2. **Interface vierge (Clean State)** : Exporter les 12 commandes mock actuelles dans un fichier de démo et démarrer le Kanban vide par défaut pour faciliter les tests avec de vraies commandes.
3. **Préparer le répertoire `inbox/`** : Connecter le dossier d'entrée surveillé par le futur service de synchronisation pour recevoir les nouvelles commandes en temps réel depuis l'app Serveur.

## Tâches

### Phase 1 : Export des Données de Démo & Clean State
- [x] Créer le répertoire `assets/samples/`
- [x] Générer `assets/samples/kitchen_demo_orders.json` contenant les 12 commandes fictives actuelles
- [x] Modifier le `KitchenProvider` (ou équivalent Riverpod) pour démarrer avec une liste vide par défaut
- [x] Ajouter un bouton *"Charger données de démo"* dans l'onglet de configuration pour restaurer les 12 commandes de test

### Phase 2 : Déport d'Affichage Chromecast & Nettoyage UI
- [x] Ajouter les dépendances Cast : `play-services-cast-framework` + `androidx.mediarouter` (approche native via MethodChannel, pas de wrapper Flutter `cast`)
- [x] Créer `lib/services/cast_service.dart` — Initialisation du Cast SDK, découverte des appareils Cast disponibles (MethodChannel `com.iel.cuisine/cast`)
- [x] Créer `lib/ui/widgets/cast_button_widget.dart` — Bouton Cast overlay dans l'appbar du Kanban ouvrant un dialogue de sélection d'appareil
- [x] Créer `lib/ui/screens/cast_kanban_receiver.dart` — Vue épurée du Kanban optimisée pour affichage TV (grande police, fort contraste)
- [x] Intégrer le maintien d'écran actif via `wakelock_plus` pendant l'affichage Kanban ou Cast
- [x] Retirer le bouton Wifi et le bouton "Kaomandy Vaovao" devenus obsolètes car le Watcher d'Inbox gère les flux automatiquement

### Phase 3 : Dossier d'Échange Réactif (Inbox pour le Service de Sync)
- [x] Créer `lib/services/sync_inbox_watcher.dart` — FileWatcher sur `sync_queue/inbox/` via `Directory.watch()` (événements `inotify` natifs)
- [x] À chaque nouveau fichier détecté : parser l'événement JSON et injecter la commande dans le `KitchenProvider` Riverpod
- [x] Déplacer le fichier traité vers `sync_queue/inbox/processed/` pour éviter les doublons

## Fichiers Concernés
| Action | Fichier |
|:---|:---|
| [NEW] | `assets/samples/kitchen_demo_orders.json` |
| [NEW] | `lib/services/cast_service.dart` |
| [NEW] | `lib/services/sync_inbox_watcher.dart` |
| [NEW] | `lib/ui/widgets/cast_button_widget.dart` |
| [NEW] | `lib/ui/screens/cast_kanban_receiver.dart` |
| [NEW] | `android/app/src/main/res/values/cast_options.xml` |
| [NEW] | `android/app/src/main/res/values/strings.xml` |
| [MODIFY] | `pubspec.yaml` — Ajout de `wakelock_plus` |
| [MODIFY] | `lib/providers/kitchen_provider.dart` (ou équivalent) — État initial vide + méthode `loadDemoOrders()` |
| [MODIFY] | `android/app/build.gradle.kts` — Dépendances `play-services-cast-framework` + `androidx.mediarouter` |
| [MODIFY] | `android/app/src/main/AndroidManifest.xml` — Permission INTERNET + services Cast |
| [MODIFY] | `android/app/src/main/kotlin/com/iel/cuisine/MainActivity.kt` — Canal natif Cast (découverte, connexion, diffusion) |
| [MODIFY] | `lib/views/kanban_view.dart` — Retrait boutons Wifi & "Kaomandy Vaovao" |

## Notes Techniques
- **Cast SDK Flutter** : Vérifier la disponibilité d'un wrapper Flutter natif pour Google Cast. Si non disponible, utiliser un `MethodChannel` vers le SDK Cast natif Android.
- **`inotify` / `Directory.watch()`** : Fonctionne nativement sur Android. Le dossier `sync_queue/inbox/` doit être dans un répertoire accessible en écriture par les deux apps (ex: répertoire de stockage externe partagé ou Content Provider Android).
