---
name: realtime-order-flow
description: Directives pour la gestion réactive en temps réel des flux de commandes en cuisine sous Flutter.
---

# Skill: Realtime Order Flow

Ce skill définit la méthodologie d'implémentation du flux de commandes en direct pour l'affichage cuisine.

## DIRECTIVES D'ARCHITECTURE
1. **Gestion des flux réactifs** :
   * Les événements de commande (Nouvelle, En préparation, Prête, Livrée) doivent transiter via des Streams.
   * Utiliser des WebSockets avec reconnexion automatique pour s'abonner au serveur central.
2. **Interface Utilisateur Réactive** :
   * Les cartes de commande en cuisine doivent avoir des couleurs claires selon l'urgence temporelle (ex: vert < 10 mins, orange 10-20 mins, rouge > 20 mins).
   * Intégrer des animations de transition fluides lorsque le cuisinier change l'état d'un ticket (tap/swipe).

## PROTOCOLE DE REFACTORING / CODE
* Toujours concevoir les widgets de ticket en les rendant légers et réutilisables.
* Prévoir des états graphiques pour la perte de connexion réseau (mode dégradé avec message clair).
