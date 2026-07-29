# Plan d'Exécution : Cohérence UI et Connexion Réseau (Cuisine)

Statut: ✅ Terminé (Implémenté dans le plan 2026-07-22--kds-complete-implementation)

Ce plan décrit les modifications à apporter à l'application Cuisine pour intégrer la découverte réseau mDNS automatique et harmoniser le comportement visuel de la connexion avec l'application Serveur.

## Proposed Changes

### Network Services & Integration

#### [MODIFY] [network_client_service.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/services/network_client_service.dart)
- Intégrer la dépendance de découverte mDNS `nsd` pour rechercher automatiquement le service `_caissecash._tcp`.
- Stocker la liste des serveurs découverts (`List<Service>`) et notifier les écouteurs.
- Tenter une connexion automatique au premier serveur valide trouvé si aucun n'est connecté.
- Gérer l'événement `ORDER_PAID` pour retirer ou archiver automatiquement la commande de la liste affichée en cuisine.

### User Interface & Widgets

#### [NEW] [network_status_indicator.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/widgets/network_status_indicator.dart)
- Composant réutilisable affichant l'état de la connexion wifi sous forme d'icône colorée et animée :
  - **Vert :** Connecté au serveur (avec IP sous forme d'infobulle ou de petit texte).
  - **Orange :** Recherche de serveur / Connexion en cours (animation de pulsation).
  - **Rouge :** Déconnecté ou erreur.
- Ce widget doit être partagé conceptuellement et visuellement avec l'application Serveur.

#### [MODIFY] [kanban_view.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/views/kanban_view.dart)
- Remplacer l'icône de statut réseau brute dans l'AppBar par le nouveau widget `NetworkStatusIndicator`.
- Mettre à jour la réactivité de la vue pour rafraîchir la liste de commandes lors d'une déconnexion/reconnexion.

#### [MODIFY] [network_connection_view.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/views/network_connection_view.dart)
- Ajouter une section "Serveurs détectés automatiquement" affichant la liste des serveurs mDNS disponibles.
- Permettre à l'utilisateur de cliquer sur un serveur découvert pour lancer la connexion instantanément.
- Utiliser le `Theme.of(context)` pour s'assurer que les couleurs s'adaptent dynamiquement au thème actif (Jour/Nuit).

## Verification Plan

### Manual Verification
1. Démarrer l'application Cuisine et le serveur de caisse fictif sur le même réseau Wifi.
2. Vérifier que le statut passe de l'orange (recherche) au vert (connecté) automatiquement.
3. Ouvrir la page de configuration réseau (`NetworkConnectionView`) et s'assurer que le serveur mDNS y est listé.
4. Envoyer une commande et modifier son statut depuis la cuisine pour valider le flux d'événements.
