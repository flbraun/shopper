import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shopper/data/item_sorting.dart';
import 'package:shopper/data/list_repository.dart';
import 'package:shopper/settings/settings.dart';
import 'package:shopper/ui/list_detail_screen.dart';

import 'test_app.dart';

/// Creates "Groceries" with items added in this order: milk, Bread, apples,
/// Coffee. Bread and Coffee are struck.
Future<void> _seed(ListRepository lists, Settings settings) async {
  final list = await lists.createList('Groceries');
  for (final text in ['milk', 'Bread', 'apples', 'Coffee']) {
    final item = await lists.addItem(list.id, text);
    if (text == 'Bread' || text == 'Coffee') {
      await lists.setStruck(item.id, true);
    }
  }
}

/// Item texts on screen, top to bottom.
List<String> _itemTexts(WidgetTester tester) => [
  for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
    (tile.title! as Text).data!,
];

bool _isStruck(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.decoration ==
    TextDecoration.lineThrough;

Future<void> _openGroceries(WidgetTester tester) async {
  await tester.tap(find.text('Groceries'));
  await settle(tester);
}

final _broom = find.byTooltip('Remove struck items');
final _undo = find.byTooltip('Undo');

void main() {
  testWidgets('default: A-Z, struck items at the bottom', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    expect(_itemTexts(tester), ['apples', 'milk', 'Bread', 'Coffee']);
    expect(_isStruck(tester, 'Bread'), isTrue);
    expect(_isStruck(tester, 'milk'), isFalse);
  });

  testWidgets('item order and struck placement follow the settings', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (lists, settings) async {
        await _seed(lists, settings);
        await settings.setItemOrder(ItemOrder.addedLatest);
        await settings.setStruckPlacement(StruckPlacement.inPlace);
      },
    );
    await _openGroceries(tester);
    expect(_itemTexts(tester), ['Coffee', 'apples', 'Bread', 'milk']);
  });

  testWidgets('tapping strikes and unstrikes; struck items move down', (
    tester,
  ) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);

    await tester.tap(find.text('apples'));
    await settle(tester);
    expect(_isStruck(tester, 'apples'), isTrue);
    expect(_itemTexts(tester), ['milk', 'apples', 'Bread', 'Coffee']);

    await tester.tap(find.text('Coffee'));
    await settle(tester);
    expect(_isStruck(tester, 'Coffee'), isFalse);
    expect(_itemTexts(tester), ['Coffee', 'milk', 'apples', 'Bread']);

    final stored = await tester.runAsync(
      () async => lists.getItems((await lists.getLists()).single.id),
    );
    expect(
      {for (final i in stored!) i.text: i.struck},
      {'milk': false, 'Bread': true, 'apples': true, 'Coffee': false},
    );
  });

  testWidgets('title screen status reflects strikes after going back', (
    tester,
  ) async {
    await pumpApp(tester, seed: _seed);
    expect(find.text('2/4'), findsOneWidget);
    await _openGroceries(tester);
    await tester.tap(find.text('milk'));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('apples'), findsOneWidget);
  });

  testWidgets('broom removes struck items; undo restores them', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);

    await tester.tap(_broom);
    await settle(tester);
    expect(_itemTexts(tester), ['apples', 'milk']);
    expect(_broom, findsNothing);
    expect(_undo, findsOneWidget);

    await tester.tap(_undo);
    await settle(tester);
    expect(_itemTexts(tester), ['apples', 'milk', 'Bread', 'Coffee']);
    expect(_isStruck(tester, 'Bread'), isTrue);
    expect(_undo, findsNothing);
    expect(_broom, findsOneWidget);

    final stored = await tester.runAsync(
      () async => lists.getItems((await lists.getLists()).single.id),
    );
    expect(stored, hasLength(4));
  });

  testWidgets('undo is offered for 5 seconds only', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);

    await tester.tap(_broom);
    await settle(tester);
    await tester.pump(
      ListDetailScreen.undoDuration - const Duration(milliseconds: 100),
    );
    expect(_undo, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(_undo, findsNothing);
    expect(_broom, findsOneWidget);

    final stored = await tester.runAsync(
      () async => lists.getItems((await lists.getLists()).single.id),
    );
    expect([for (final i in stored!) i.text], ['milk', 'apples']);
  });

  testWidgets('broom is disabled without struck items', (tester) async {
    await pumpApp(
      tester,
      seed: (lists, _) async {
        final list = await lists.createList('Groceries');
        await lists.addItem(list.id, 'milk');
      },
    );
    await _openGroceries(tester);
    final button = tester.widget<IconButton>(
      find.ancestor(of: _broom, matching: find.byType(IconButton)),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('empty list shows the empty state', (tester) async {
    await pumpApp(
      tester,
      locale: const Locale('de'),
      seed: (lists, _) async => lists.createList('Groceries'),
    );
    await _openGroceries(tester);
    expect(find.text('Noch keine Einträge.'), findsOneWidget);
  });
}
