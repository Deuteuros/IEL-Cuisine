import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuisine/main.dart';

void main() {
  testWidgets('App renders with KanbanView', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: CuisineApp(),
      ),
    );

    expect(find.text('Lakozia'), findsOneWidget);
    expect(find.text('HATAO'), findsOneWidget);
    expect(find.text('AM-PIKARAKARANA'), findsOneWidget);
    expect(find.text('VITA'), findsOneWidget);

    await tester.pump();
  });
}
