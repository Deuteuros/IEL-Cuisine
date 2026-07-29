# Plan d'Exécution : Support Multi-thème (Jour/Nuit)

Ce plan décrit l'implémentation de la fonctionnalité de basculement entre le mode Jour (Light) et le mode Nuit (Dark) pour l'application Cuisine Lakozia.

## Proposed Changes

### Cuisine App UI / Styling

#### [NEW] [theme_provider.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/providers/theme_provider.dart)
- Création d'un provider Riverpod qui gère le `ThemeMode` (ex: `ThemeMode.dark` ou `ThemeMode.light`).
- Persistance locale simple ou en mémoire de la sélection de l'utilisateur.

#### [MODIFY] [main.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/main.dart)
- Transformation de `CuisineApp` en `ConsumerWidget`.
- Lecture du `themeProvider` pour configurer le `themeMode`, le `theme` (Light Mode) et le `darkTheme` (Dark Mode) de `MaterialApp`.
- Définition propre des thèmes Light et Dark basés sur `Outfit` et la couleur de base `0xFFE64A19`.

#### [MODIFY] [kanban_view.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/views/kanban_view.dart)
- Remplacement des couleurs d'arrière-plan dures (`0xFF0F0F12`, `0xFF16161E`) par des valeurs dynamiques issues du thème actuel (`Theme.of(context)`).
- Ajout d'un bouton d'action dans l'AppBar pour basculer de thème de façon fluide (changement d'icône Soleil/Lune).
- Adaptation visuelle des cartes Kanban et de la boîte de dialogue des détails de commande pour garder un contraste de texte parfait en mode jour et nuit.

#### [MODIFY] [network_connection_view.dart](file:///home/deuteuros/Documents/10%20Projets/IEL%20-%20Application%20Cuisine/lib/views/network_connection_view.dart)
- Dynamisation des couleurs de fond, des cartes de statut et des champs de saisie pour s'adapter au thème actif.

## Verification Plan

### Manual Verification
1. Lancement de l'application.
2. Clic sur le bouton de thème dans l'AppBar.
3. Vérification de la transition visuelle (les couleurs passent au blanc/gris clair avec du texte foncé sans altérer la lisibilité).
4. Validation du fonctionnement de la boîte de dialogue de détails sous les deux thèmes.
