import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:viral_imagetovideo_app/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('renders onboarding headline', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transform Images to Videos'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
