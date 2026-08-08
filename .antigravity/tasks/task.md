# Task List - IEL Cuisine (Lakozia)

## 📋 Tâches Prioritaires — Déport TV & Réseau Découplé

- [x] **Phase 1 : Clean State & Samples** ✅
  - [x] Exporter les 12 commandes fictives actuelles vers `assets/samples/kitchen_demo_orders.json`
  - [x] Initialiser le Kanban sur une vue vierge par défaut

- [x] **Phase 2 : Déport d'Affichage Chromecast / Android TV** ✅
  - [x] Intégrer le SDK Google Cast / Chromecast pour déporter la vue Kanban sur écran TV (via `MethodChannel` natif `com.iel.cuisine/cast` + `play-services-cast-framework` dans `MainActivity.kt`)
  - [x] Intégrer `wakelock_plus` pour maintenir l'écran actif en cuisine

- [x] **Phase 3 : Échange Réseau Réactif (Inbox Queue)** ✅
  - [x] Connecter l'application au dossier `inbox/` alimenté par le service de synchronisation
  - [x] Mettre à jour l'interface Kanban en temps réel à la réception d'un événement fichier

- [x] **Phase 4 : Nettoyage UI & Boîte de Dialogue Chromecast** ✅
  - [x] Retirer le bouton Wifi et le bouton "Kaomandy Vaovao" de l'interface (devenus inutiles grâce au service d'arrière-plan)
  - [x] Implémenter le dialogue de sélection Chromecast pour rechercher et choisir la TV de diffusion

---

## ⏳ Reste à faire / À vérifier

- [ ] **Vérifier le build Android natif** : `flutter build apk --debug` (nécessite un accès réseau pour télécharger `play-services-cast-framework` + `androidx.mediarouter`). Si erreur de compilation Kotlin sur l'interface `SessionManagerListener`, corriger les signatures.
- [ ] **Pusher la branche `main`** (en avance de 2 commits sur `origin/main`).
- [ ] Committer les changements en attente (natif Cast Android, nettoyage UI AppBar, fichiers resources).

---

## ✅ Historique Accompli
- [x] Concevoir le design visuel des cartes de commande (KDS)
- [x] Ajouter les actions tactiles (swipe / drag & drop pour marquer comme prêt)
- [x] Vue détaillée des commandes au clic
