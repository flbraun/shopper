import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shopper/data/list_repository.dart';
import 'package:shopper/settings/settings.dart';

import 'test_app.dart';

/// "Groceries" (milk, struck Bread) and "Other". The dictionary also knows
/// Buttermilk, Milka and Oat milk from "Other".
Future<void> _seed(ListRepository lists, Settings _) async {
  final groceries = await lists.createList('Groceries');
  await lists.addItem(groceries.id, 'milk');
  final bread = await lists.addItem(groceries.id, 'Bread');
  await lists.setStruck(bread.id, true);
  final other = await lists.createList('Other');
  for (final text in ['Oat milk', 'Milka', 'Buttermilk']) {
    await lists.addItem(other.id, text);
  }
}

final _field = find.byType(TextField);

Future<void> _openGroceries(WidgetTester tester) async {
  await tester.tap(find.text('Groceries'));
  await settle(tester);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await settle(tester);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester);
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(_field).controller!.text;

List<String> _itemTexts(WidgetTester tester) => [
  for (final tile in tester.widgetList<ListTile>(
    find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(ListTile),
    ),
  ))
    (tile.title! as Text).data!,
];

Future<List<(String, bool)>> _stored(
  WidgetTester tester,
  ListRepository lists,
) async {
  final items = await tester.runAsync(
    () async => lists.getItems((await lists.getLists()).first.id),
  );
  return [for (final i in items!) (i.text, i.struck)];
}

void main() {
  testWidgets('submitting adds a trimmed item, clears the field and keeps '
      'focus', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);

    await _type(tester, '  Eggs  ');
    await _submit(tester);

    expect(_itemTexts(tester), ['Eggs', 'milk', 'Bread']);
    expect(_fieldText(tester), isEmpty);
    expect(tester.widget<TextField>(_field).focusNode!.hasFocus, isTrue);
    expect(await _stored(tester, lists), [
      ('milk', false),
      ('Bread', true),
      ('Eggs', false),
    ]);
    expect(await tester.runAsync(() => lists.dictionary.suggestions('egg')), [
      'Eggs',
    ]);
  });

  testWidgets('empty input adds nothing', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    await _type(tester, '   ');
    await _submit(tester);
    expect(await _stored(tester, lists), hasLength(2));
  });

  testWidgets('suggestions: contains, prefix first, items on the list '
      'included', (tester) async {
    await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    await _type(tester, 'MIL');

    final options = find.descendant(
      of: find.byType(ListView).last,
      matching: find.byType(Text),
    );
    expect(
      [for (final t in tester.widgetList<Text>(options)) t.data],
      ['milk', 'Milka', 'Buttermilk', 'Oat milk'],
    );
  });

  testWidgets('enter adds the typed text, not the first suggestion', (
    tester,
  ) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    await _type(tester, 'Butter');
    await _submit(tester);
    expect((await _stored(tester, lists)).last, ('Butter', false));
  });

  testWidgets('tapping a suggestion adds it', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    await _type(tester, 'oat');
    await tester.tap(find.text('Oat milk'));
    await settle(tester);

    expect(_fieldText(tester), isEmpty);
    expect((await _stored(tester, lists)).last, ('Oat milk', false));
    expect(find.text('Oat milk'), findsOneWidget);
  });

  testWidgets('duplicate: cancel adds nothing and keeps the text', (
    tester,
  ) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    await _type(tester, 'MILK');
    await _submit(tester);

    expect(find.text('Already on the list'), findsOneWidget);
    expect(
      find.text('"MILK" is already on this list. Add it a second time?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(await _stored(tester, lists), hasLength(2));
    expect(_fieldText(tester), 'MILK');
  });

  testWidgets('duplicate of a struck item: "Add anyway" adds a second, '
      'unstruck item', (tester) async {
    final (:lists, settings: _) = await pumpApp(tester, seed: _seed);
    await _openGroceries(tester);
    await _type(tester, 'bread');
    await _submit(tester);
    await tester.tap(find.text('Add anyway'));
    await settle(tester);

    expect(await _stored(tester, lists), [
      ('milk', false),
      ('Bread', true),
      ('bread', false),
    ]);
    expect(_itemTexts(tester), ['bread', 'milk', 'Bread']);
    expect(_fieldText(tester), isEmpty);
  });

  testWidgets('duplicate dialog in German', (tester) async {
    await pumpApp(tester, locale: const Locale('de'), seed: _seed);
    await _openGroceries(tester);
    await _type(tester, 'Milk');
    await _submit(tester);
    expect(find.text('Bereits auf der Liste'), findsOneWidget);
    expect(
      find.text(
        '„Milk“ ist bereits auf dieser Liste. Ein zweites Mal '
        'hinzufügen?',
      ),
      findsOneWidget,
    );
    expect(find.text('Trotzdem hinzufügen'), findsOneWidget);
  });
}
