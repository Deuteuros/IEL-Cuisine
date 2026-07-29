# Plan d'Exécution : Implémentation Complète du KDS (Cuisine)

Ce plan décrit les modifications nécessaires pour finaliser les 4 missions en attente sur l'application Cuisine (Lakozia).

Statut : ✅ Terminé (Implémenté par OpenCode le 2026-07-22)

---

## 1. Conception Visuelle des Cartes de Commande (KDS)

### Objectif
Transformer la carte de commande actuelle (`_OrderCard` dans `lib/views/kanban_view.dart`) qui n'affiche que le numéro de table en une vraie carte KDS riche et lisible d'un coup d'œil par les cuisiniers.

### Spécifications du Design
- **En-tête de la carte :**
  - Numéro de table bien visible (ex: `Table 3`).
  - Timer relatif indiquant depuis combien de temps la commande a été créée (ex: `12m 30s`), avec changement de couleur dynamique :
    - Vert : < 10 minutes
    - Orange : 10 à 20 minutes
    - Rouge : > 20 minutes
- **Liste des articles :**
  - Affichage direct de la liste des plats de la commande.
  - Formater ainsi : `[Quantité] [Nom du plat]`.
  - Mettre en valeur les quantités (ex: badge ou texte en gras coloré).
  - Afficher les **notes spécifiques** (ex: "Sans oignons") de manière très visible (ex: fond rouge/orange léger avec icône d'avertissement).
- **Style visuel :**
  - Utiliser des bordures de couleur selon le statut de la commande ou le niveau d'urgence (timer).
  - Design sombre premium (couleurs existantes ou adaptées du thème).

---

## 2. Actions Tactiles (Swipe/Glisser pour marquer prêt)

### Objectif
Permettre aux cuisiniers de changer le statut d'une commande rapidement par un geste de glissement (swipe) sur la carte, sans avoir à faire un drag & drop complet sur tablette.

### Spécifications
- Envelopper la carte dans un widget `Dismissible` (ou similaire) dans `lib/views/kanban_view.dart`.
- **Comportement :**
  - Si la commande est dans la colonne **HATAO** (À faire), un swipe vers la droite ou la gauche la déplace vers **AM-PIKARAKARANA** (En cours).
  - Si elle est dans **AM-PIKARAKARANA**, un swipe la déplace vers **VITA** (Fait).
  - Si elle est dans **VITA**, un swipe l'archive/supprime (en déclenchant `onOrderPaid` ou similaire).
- **Indicateurs visuels pendant le swipe :**
  - Afficher un fond coloré sous la carte pendant le glissement (ex: bleu pour "Démarrer la préparation", vert pour "Prêt", rouge/gris pour "Archiver") avec une icône appropriée.

---

## 3. Connexion Client WebSocket au Backend

### Objectif
S'assurer que la communication bidirectionnelle en temps réel est opérationnelle avec le serveur IEL.

### Spécifications
- Revoir `lib/services/network_client_service.dart`.
- S'assurer que les événements locaux (`moveOrder` initié par swipe ou drag-and-drop) envoient bien le message `UPDATE_STATUS` au serveur via WebSocket.
- Gérer la reconnexion automatique en cas de coupure réseau avec un intervalle progressif (exponential backoff).
- Gérer l'état de connexion de manière robuste et notifier la UI.

---

## 4. Auto-découverte mDNS du Service `_caissecash._tcp`

### Objectif
Permettre à l'application Cuisine de trouver automatiquement l'IP et le port de l'application Serveur sur le réseau local sans saisie manuelle.

### Spécifications
- **Dépendances :** Ajouter `nsd: ^2.1.0` à `pubspec.yaml`.
- **Service mDNS :**
  - Dans `lib/services/network_client_service.dart`, ajouter une méthode pour démarrer la découverte du service type `_caissecash._tcp`.
  - Dès qu'un service est découvert et résolu, l'application doit tenter de s'y connecter automatiquement.
- **Interface Utilisateur :**
  - Dans `lib/views/network_connection_view.dart`, ajouter une liste des "Serveurs trouvés sur le réseau local" en utilisant les résultats du scan mDNS en cours.
  - Permettre de cliquer sur un serveur découvert pour s'y connecter manuellement si la connexion automatique n'a pas été déclenchée.

---

## Fichiers à modifier / créer

### `pubspec.yaml`
- Ajouter `nsd: ^2.1.0` sous `dependencies`.

### `lib/services/network_client_service.dart`
- Intégrer les fonctionnalités mDNS avec `nsd`.
- Ajouter la logique d'auto-reconnexion et d'écoute mDNS.

### `lib/views/kanban_view.dart`
- Modifier `_OrderCard` pour afficher les détails des articles de la commande et le timer dynamique.
- Ajouter le widget `Dismissible` autour de la carte pour supporter le geste de swipe selon la colonne.

### `lib/views/network_connection_view.dart`
- Afficher les serveurs découverts par mDNS.

---

## Plan de vérification

### Test d'auto-découverte & WebSocket
1. Lancer le serveur (Caisse) qui doit publier le service `_caissecash._tcp` via mDNS.
2. Lancer l'application Cuisine. Elle doit détecter le serveur et s'y connecter en quelques secondes (icône réseau verte dans l'AppBar).

### Test des cartes KDS & Swipe
1. Envoyer une commande fictive.
2. Vérifier que la carte affiche le numéro de table, le timer actif qui s'incrémente, et tous les articles avec leurs quantités et notes.
3. Swiper la carte vers la droite dans la colonne "HATAO". Elle doit passer dans la colonne "AM-PIKARAKARANA".
4. Swiper à nouveau. Elle doit passer dans "VITA".
5. Vérifier dans la console (ou sur le serveur) que les événements `UPDATE_STATUS` correspondants ont été transmis.
