# Task List - IEL Cuisine (Lakozia)

## 📋 Tâches Prioritaires — Déport TV & Réseau Découplé

- [ ] **Phase 1 : Clean State & Samples**
  - [ ] Exporter les 12 commandes fictives actuelles vers `assets/samples/kitchen_demo_orders.json`
  - [ ] Initialiser le Kanban sur une vue vierge par défaut

- [ ] **Phase 2 : Déport d'Affichage Chromecast / Android TV**
  - [ ] Intégrer le SDK Google Cast / Chromecast pour déporter la vue Kanban sur écran TV
  - [ ] Intégrer `wakelock_plus` pour maintenir l'écran actif en cuisine

- [ ] **Phase 3 : Échange Réseau Réactif (Inbox Queue)**
  - [ ] Connecter l'application au dossier `inbox/` alimenté par le service de synchronisation
  - [ ] Mettre à jour l'interface Kanban en temps réel à la réception d'un événement fichier

---

## ✅ Historique Accompli
- [x] Concevoir le design visuel des cartes de commande (KDS)
- [x] Ajouter les actions tactiles (swipe / drag & drop pour marquer comme prêt)
- [x] Vue détaillée des commandes au clic
