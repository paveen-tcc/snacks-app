import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/core/design/glass.dart';

void main() {
  testWidgets('bottom sheet uses an opaque themed surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showGlassBottomSheet<void>(
                context: context,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Sheet content'),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('app_bottom_sheet_surface'));
    expect(surface, findsOneWidget);
    expect(tester.widget<Material>(surface).color, const Color(0xFFFFFFFF));
    expect(
      find.descendant(of: surface, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(find.text('Sheet content'), findsOneWidget);
  });
}
