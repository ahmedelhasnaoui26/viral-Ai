import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viral_imagetovideo_app/shared/widgets/viral_bottom_nav.dart';

void main() {
  Future<void> pumpNav(WidgetTester tester, Size logicalSize) async {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: logicalSize),
          child: Scaffold(
            bottomNavigationBar: ViralBottomNav(
              currentTab: ViralNavTab.home,
              onTabSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bottom nav fits iPhone SE (667h)', (tester) async {
    await pumpNav(tester, const Size(375, 667));
    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('bottom nav fits iPhone 15 Pro (852h)', (tester) async {
    await pumpNav(tester, const Size(393, 852));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom nav fits iPhone 17 Pro class (932h)', (tester) async {
    await pumpNav(tester, const Size(430, 932));
    expect(tester.takeException(), isNull);
  });
}
