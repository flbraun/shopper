import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopper/app.dart';

void main() {
  testWidgets('title screen shows the empty state in English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ShopperApp());
    await tester.pumpAndSettle();

    expect(find.text('Shopper'), findsOneWidget);
    expect(find.text('No lists yet.'), findsOneWidget);
  });

  testWidgets('title screen shows the empty state in German', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ShopperApp());
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Listen.'), findsOneWidget);
  });
}
