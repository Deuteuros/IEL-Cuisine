# Context Root & Agent Mandate - IEL Cuisine

Ce fichier est la racine de contexte local pour l'assistant **Antigravity** lorsqu'il intervient sur le dépôt **IEL - Cuisine**.

## Mandat du Projet
Le projet [IEL - Cuisine](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Cuisine) est une application mobile et tablette Flutter gérant l'affichage en temps réel des commandes en cours de préparation en cuisine (Kitchen Display System). Elle communique avec [IEL - Serveur (Cuisine)](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Serveur%20(Cuisine)).

## Compétences (Skills) Locales
* **`realtime-order-flow`** : Gestion des flux réactifs sous Flutter (WebSockets, Streams) et interface utilisateur interactive pour tablette cuisine.
  * Emplacement : [.antigravity/skills/realtime-order-flow/SKILL.md](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Cuisine/.antigravity/skills/realtime-order-flow/SKILL.md)

## Compétences (Skills) Globales
* **`git-manager`** : Gestion complète du dépôt Git — création de branches, merges, résolution de conflits, commits (Conventional Commits), push/pull sécurisé.
  * Plugin : `git-manager-plugin` (global, disponible dans tous les projets Antigravity)

## Sous-Agents Définis
* **`cuisine-ui-developer`** : Développeur Flutter spécialisé dans les interfaces interactives pour tablettes et la gestion réactive d'état graphique.
  * Configuration : [.antigravity/subagents/cuisine-ui-developer.md](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Cuisine/.antigravity/subagents/cuisine-ui-developer.md)

## Règle de Développement (Git & Branches)
* **Workflow de branchement** : Pour toute nouvelle fonctionnalité, l'assistant doit obligatoirement utiliser Git en créant une branche dédiée (ex: `feature/nom-fonctionnalite`).
* **Validation & Rollback** : Travailler exclusivement sur cette branche pour isoler le code et permettre un retour arrière rapide en cas de blocage. Fusionner la branche vers la branche principale uniquement après validation fonctionnelle et tests de la fonctionnalité.

## Suivi Stratégique
* QG Stratégique Obsidian : `Efforts/Projects/IEL - Cuisine.md` dans l'Ideaverse.
* Tâches d'implémentation courantes : [.antigravity/tasks/task.md](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Cuisine/.antigravity/tasks/task.md)
