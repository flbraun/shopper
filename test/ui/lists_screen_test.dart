import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shopper/data/list_repository.dart';
import 'package:shopper/settings/settings.dart';

import 'test_app.dart';

Future<void> _seedThree(ListRepository lists, Settings _) async {
  for (final name in ['A', 'B', 'C']) {
    await lists.createList(name);
  }
}

/// Long-presses the card titled [name] and returns the gesture, ready to
/// be moved.
Future<TestGesture> _startDrag(WidgetTester tester, String name) async {
  final gesture = await tester.startGesture(tester.getCenter(find.text(name)));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('empty state in English', (tester) async {
    await pumpApp(tester);
    expect(find.text('Shopper'), findsOneWidget);
    expect(find.text('No lists yet.'), findsOneWidget);
    expect(find.text('New list'), findsOneWidget);
  });

  testWidgets('empty state in German', (tester) async {
    await pumpApp(tester, locale: const Locale('de', 'DE'));
    expect(find.text('Noch keine Listen.'), findsOneWidget);
    expect(find.text('Neue Liste'), findsOneWidget);
  });

  testWidgets('cards show unstruck items as preview and struck/total', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (lists, _) async {
        final list = await lists.createList('Groceries');
        await lists.addItem(list.id, 'milk');
        final bread = await lists.addItem(list.id, 'Bread');
        await lists.addItem(list.id, 'apples');
        await lists.setStruck(bread.id, true);
        await lists.createList('Empty');
      },
    );
    expect(find.text('apples, milk'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
    expect(find.text('No lists yet.'), findsNothing);
  });

  testWidgets('new list: trimmed, appended at the bottom', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seedThree);
    await tester.tap(find.text('New list'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Hardware  ');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await settle(tester);

    expect(listNames(tester), ['A', 'B', 'C', 'Hardware']);
    final stored = await tester.runAsync(lists.getLists);
    expect(stored!.last.name, 'Hardware');
  });

  testWidgets('new list: empty or taken names cannot be created', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seedThree);
    await tester.tap(find.text('New list'));
    await tester.pumpAndSettle();

    Finder createButton() => find.widgetWithText(TextButton, 'Create');
    bool createEnabled() =>
        tester.widget<TextButton>(createButton()).onPressed != null;

    expect(createEnabled(), isFalse);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(createEnabled(), isFalse);

    await tester.enterText(find.byType(TextField), ' b ');
    await tester.pump();
    expect(createEnabled(), isFalse);
    expect(find.text('A list with this name already exists.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'D');
    await tester.pump();
    expect(createEnabled(), isTrue);
    expect(find.text('A list with this name already exists.'), findsNothing);
  });

  testWidgets('drag and drop reorders lists and stores the order', (
    tester,
  ) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seedThree);
    final gesture = await _startDrag(tester, 'A');
    final step = tester.getSize(find.byType(Card).first).height + 8;
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, step * 1.1 / 10));
      await tester.pump();
    }
    await gesture.up();
    await settle(tester);

    expect(listNames(tester), ['B', 'A', 'C']);
    final stored = await tester.runAsync(lists.getLists);
    expect([for (final l in stored!) l.name], ['B', 'A', 'C']);
  });

  testWidgets('bin appears while dragging and deletes the dropped list', (
    tester,
  ) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seedThree);
    final bin = find.bySemanticsLabel('Drop here to delete the list');
    expect(bin, findsNothing);

    final gesture = await _startDrag(tester, 'B');
    await gesture.moveBy(const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(bin, findsOneWidget);

    final target = tester.getCenter(bin);
    final start = tester.getCenter(find.text('B'));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, target, i / 10)!);
      await tester.pump();
    }
    await gesture.up();
    await settle(tester);

    expect(bin, findsNothing);
    expect(listNames(tester), ['A', 'C']);
    final stored = await tester.runAsync(lists.getLists);
    expect([for (final l in stored!) l.name], ['A', 'C']);
  });

  testWidgets('dropping a list elsewhere does not delete it', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seedThree);
    final gesture = await _startDrag(tester, 'C');
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.up();
    await settle(tester);

    expect(listNames(tester), ['A', 'B', 'C']);
    expect(await tester.runAsync(lists.getLists), hasLength(3));
  });
}
