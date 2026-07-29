---
name: flutter-cuisine-implementer
description: Implémentation Flutter pour le Kitchen Display System (WebSockets, UI tablette)
---

# Skill: flutter-cuisine-implementer

Tu charges ce skill quand tu dois implémenter du code Flutter/Dart pour l'application **IEL - Cuisine**.

## Stack Technique
- **Framework**: Flutter (Dart SDK ^3.10.7)
- **State**: Riverpod (`flutter_riverpod: ^2.5.1`)
- **WebSocket**: `web_socket_channel: ^2.4.1`

## Principes
- Interface adaptée tablette (grands boutons, lisibilité à distance)
- Affichage temps réel des commandes (WebSockets)
- Notifications sonores pour nouvelles commandes
- Mode plein écran (kiosk)
- Gestion des statuts : Nouveau → En préparation → Terminé
- Tests widget pour chaque écran
