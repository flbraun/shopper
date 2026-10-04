import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shopper/data/item_sorting.dart';
import 'package:shopper/settings/settings.dart';

import 'test_app.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

bool _selected<T>(WidgetTester tester, String label) {
  final tile = find.ancestor(
    of: find.text(label),
    matching: find.byType(RadioListTile<T>),
  );
  final value = tester.widget<RadioListTile<T>>(tile).value;
  final group = tester.widget<RadioGroup<T>>(
    find.ancestor(of: tile, matching: find.byType(RadioGroup<T>)),
  );
  return group.groupValue == value;
}

void main() {
  testWidgets('shows the defaults', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(_selected<ItemOrder>(tester, 'A–Z'), isTrue);
    expect(_selected<ItemOrder>(tester, 'Z–A'), isFalse);
    expect(_selected<StruckPlacement>(tester, 'Move to the bottom'), isTrue);
    expect(_selected<StruckPlacement>(tester, 'Keep in place'), isFalse);
  });

  testWidgets('changes apply immediately and are stored', (tester) async {
    final (lists: _, :settings) = await pumpApp(tester);
    await _openSettings(tester);

    await tester.tap(find.text('Added latest first'));
    await tester.tap(find.text('Keep in place'));
    await tester.pumpAndSettle();

    expect(_selected<ItemOrder>(tester, 'Added latest first'), isTrue);
    expect(_selected<StruckPlacement>(tester, 'Keep in place'), isTrue);
    expect(settings.itemOrder, ItemOrder.addedLatest);
    expect(settings.struckPlacement, StruckPlacement.inPlace);

    final reloaded = await tester.runAsync(Settings.load);
    expect(reloaded!.itemOrder, ItemOrder.addedLatest);
    expect(reloaded.struckPlacement, StruckPlacement.inPlace);
  });

  testWidgets('title screen preview follows the item order', (tester) async {
    await pumpApp(
      tester,
      seed: (lists, _) async {
        final list = await lists.createList('Groceries');
        for (final text in ['milk', 'apples', 'Bread']) {
          await lists.addItem(list.id, text);
        }
      },
    );
    expect(find.text('apples, Bread, milk'), findsOneWidget);
    await _openSettings(tester);
    await tester.tap(find.text('Z–A'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('milk, Bread, apples'), findsOneWidget);
  });

  testWidgets('German labels', (tester) async {
    await pumpApp(tester, locale: const Locale('de'));
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    for (final label in [
      'Reihenfolge der Einträge',
      'Zuerst hinzugefügte zuerst',
      'Zuletzt hinzugefügte zuerst',
      'Erledigte Einträge',
      'An ihrer Stelle lassen',
      'Nach unten verschieben',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  test('settings stored by an earlier app start are used', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          Settings.itemOrderKey: ItemOrder.za.name,
        });
    expect((await Settings.load()).itemOrder, ItemOrder.za);
  });
}
