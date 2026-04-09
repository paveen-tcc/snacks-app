import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snacks_app/presentation/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen renders primary sign-in content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );

    expect(find.text('Welcome to Snacks'), findsOneWidget);
    expect(find.text('Sign in with Microsoft'), findsOneWidget);
  });
}
