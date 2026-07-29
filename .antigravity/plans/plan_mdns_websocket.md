# Plan: 2026-07-16 - WebSocket mDNS Cuisine Auto-Discovery

Statut: ✅ Terminé (Implémenté dans le plan 2026-07-22--kds-complete-implementation)

## Description
Mettre en place la découverte mDNS automatique du serveur de caisse dans l'application Cuisine pour une connexion zéro-configuration au démarrage.

## Tâches
- [ ] **Tâche 1 : Ajouter la dépendance `nsd`**
  - Fichier concerné : `pubspec.yaml`
  - Description : Ajouter la dépendance `nsd: ^2.1.0` dans `dependencies`.

- [ ] **Tâche 2 : Implémenter la découverte et la connexion automatique**
  - Fichier concerné : `lib/services/network_client_service.dart`
  - Description : Démarrer un scan mDNS pour localiser le service `_caissecash._tcp` dès le lancement de l'application ou en cas de déconnexion. Une fois trouvé, se connecter automatiquement à l'adresse IP et au port résolus.
