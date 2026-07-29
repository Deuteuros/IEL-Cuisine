# Changelog

Toutes les modifications notables de l'application Cuisine — Lakozia sont documentées ici.

Format basé sur [Keep a Changelog](https://keepachangelog.com/),
et le projet suit [Semantic Versioning](https://semver.org/).

## [1.1.0] — 2026-07-29

### Nouvelles fonctionnalités

- **Multi-thème (Jour/Nuit)** : Basculement fluide entre mode clair et sombre via un bouton dans l'AppBar. Toutes les vues s'adaptent dynamiquement (Kanban, NetworkConnection, Dialogues).
- **Clean State & Données de Démo** : Le Kanban démarre vide. 12 commandes fictives exportées dans `assets/samples/kitchen_demo_orders.json`. Bouton *"Charger données de démo"* disponible.
- **Déport Chromecast / Android TV (préparation)** : Architecture Cast via MethodChannel (`CastService`), bouton Cast overlay dans l'AppBar, vue TV épurée (`CastKanbanReceiver`).
- **Maintien d'écran actif** : Intégration de `wakelock_plus` pour éviter la mise en veille en cuisine.
- **FileWatcher Inbox (Sync)** : Surveillance du dossier `sync_queue/inbox/` via `Directory.watch()` (inotify). Traitement automatique des fichiers JSON de commandes et déplacement vers `processed/`.

### Corrections

- Mauvais timing d'initialisation mDNS déplacé dans `addPostFrameCallback`.
- Couleurs d'interface dynamiques via `Theme.of(context).colorScheme` au lieu de valeurs hard-codées.
- Nom de l'application Android mis à jour : "Lakozia".
- Nouveaux icônes de lancement Android & iOS.

### Maintenance

- Ajout des dépendances : `wakelock_plus`, `path_provider`.
- Configuration Android : signing config release, `key.properties`.
- Asset pipeline : `assets/icons/`, `assets/samples/`.

## [1.0.0] — 2026-07-22

### Nouvelles fonctionnalités

- Interface Kanban trois colonnes (HATAO / AM-PIKARAKARANA / VITA)
- Cartes de commande KDS riches (timer, liste articles, notes, badges)
- Actions tactiles (swipe et drag-and-drop entre colonnes)
- WebSocket client connecté au backend IEL Serveur (Caisse)
- Auto-découverte mDNS du service `_caissecash._tcp`
- Vue détaillée des commandes au clic
- Thème sombre Material3
- Icônes et branding Lakozia
