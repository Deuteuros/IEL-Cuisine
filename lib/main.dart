import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/kanban_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CuisineApp(),
    ),
  );
}

class CuisineApp extends StatelessWidget {
  const CuisineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuisine — Lakozia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE64A19), // Orange / Hot Food theme
          brightness: Brightness.dark,       // Cuisine is often dark mode for readability
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const KanbanView(),
    );
  }
}
