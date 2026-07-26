# Context Root & Agent Mandate - IEL Cuisine

## Architecture Hybride à Deux Couches

```
Gemini/Claude (via Antigravity) ─── Plan d'Exécution ───→ DeepSeek/GLM/Kimi/MiniMax (via OpenCode)
         ↑                                                    ↑
    STRATÈGE (Planner)                                    IMPLÉMENTEUR (Coder)
    - Analyse le besoin                                    - Reçoit le plan
    - Décompose en tâches                                  - Écrit le code
    - Produit les plans dans .antigravity/plans/           - Teste & valide
    - Délègue l'implémentation à OpenCode                  - Livre le résultat
```

### Protocole de Handoff (Planificateur → Implémenteur)
1. **Antigravity** (Gemini/Claude) analyse la demande et produit un Plan d'Exécution dans `.antigravity/plans/`.
2. **OpenCode** (DeepSeek/GLM/Kimi/MiniMax) est invoqué avec `opencode` depuis la racine du projet.
3. OpenCode lit le dernier plan dans `.antigravity/plans/`.
4. **Phase Recherche** *(optionnelle)* : Si le plan implique des technologies/librairies inconnues du codebase, OpenCode génère un Master Prompt Perplexity → User télécharge les sources dans `docs/research/` → OpenCode valide (boucle jusqu'à saturation). Si le plan est suffisamment détaillé et le contexte maîtrisé, cette phase est sautée.
5. **Phase Implémentation** : OpenCode exécute les tâches avec le contexte des sources.
6. OpenCode marque le plan comme `✅ Terminé`.

## Mandat du Projet
Le projet [IEL - Cuisine](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine) est une application mobile et tablette Flutter gérant l'affichage en temps réel des commandes en cours de préparation en cuisine (Kitchen Display System). Elle communique avec [IEL - Serveur (Cuisine)](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Serveur).

## Compétences (Skills) Locales — Antigravity
* **`realtime-order-flow`** : Gestion des flux réactifs sous Flutter (WebSockets, Streams) et interface utilisateur interactive pour tablette cuisine.
  * Emplacement : [.antigravity/skills/realtime-order-flow/SKILL.md](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/.antigravity/skills/realtime-order-flow/SKILL.md)

## Compétences (Skills) Globales — Antigravity
* **`git-manager`** : Gestion complète du dépôt Git — création de branches, merges, résolution de conflits, commits (Conventional Commits), push/pull sécurisé.
  * Plugin : `git-manager-plugin` (global, disponible dans tous les projets Antigravity)

## Sous-Agents Antigravity (Planification)
* **`cuisine-ui-developer`** : Développeur Flutter spécialisé dans les interfaces interactives pour tablettes et la gestion réactive d'état graphique.
  * Configuration : [.antigravity/subagents/cuisine-ui-developer.md](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/.antigravity/subagents/cuisine-ui-developer.md)
* **`implementation-delegator`** : Délègue l'exécution du code à OpenCode en écrivant des plans clairs dans `.antigravity/plans/`.

## Agents OpenCode (Implémentation)
Les agents d'implémentation sont définis dans `.opencode/agents/` et sont exécutés par la CLI OpenCode avec les modèles open-weight :
| Agent | Modèle | Rôle |
| :--- | :--- | :--- |
| `flutter-ui-implementer` | DeepSeek | Implémentation UI Flutter pour la cuisine |
| `websocket-client-implementer` | GLM | Client WebSocket et streams réactifs |
| `tester` | Kimi | Tests unitaires et widget tests |
| `integrator` | MiniMax | Intégration avec le Serveur central |

## Règle de Développement (Git & Branches)
* **Workflow de branchement** : Pour toute nouvelle fonctionnalité, créer une branche dédiée (ex: `feature/nom-fonctionnalite`).
* **Validation & Rollback** : Travailler exclusivement sur cette branche pour isoler le code et permettre un retour arrière rapide en cas de blocage. Fusionner vers la branche principale uniquement après validation fonctionnelle et tests.
* **Commit par OpenCode** : Les commits sont effectués par l'agent implémenteur OpenCode avec Conventional Commits.
* **Changelog** : Mettre à jour `CHANGELOG.md` à chaque release majeure ou mineure. Documenter dans l'ordre : nouvelles fonctionnalités, corrections, maintenance. Utiliser le format [Keep a Changelog](https://keepachangelog.com/).

## Processus Connectés

* **[[Process - Research-Driven Vibe-Coding]]** — Boucle recherche → implémentation (dans l'Ideaverse /Atlas/Process/)
* **[[Process - Incremental Code Review]]** — Review espacée avec org-fc + agents Feynman (dans l'Ideaverse /Atlas/Process/)

## Suivi Stratégique
* QG Stratégique Obsidian : `Efforts/Projects/IEL - Cuisine.md` dans l'Ideaverse.
* Tâches d'implémentation courantes : [.antigravity/tasks/task.md](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/.antigravity/tasks/task.md)
* Plans d'exécution : `.antigravity/plans/` (générés par Antigravity, consommés par OpenCode)
