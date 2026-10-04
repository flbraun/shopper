import 'package:flutter_test/flutter_test.dart';
import 'package:shopper/data/dictionary_repository.dart';
import 'package:shopper/data/list_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_db.dart';

void main() {
  late Database db;
  late ListRepository repo;

  setUp(() async {
    db = await openTestDatabase();
    repo = ListRepository(db, clock: steppingClock());
  });

  tearDown(() => db.close());

  group('lists', () {
    test('new lists are trimmed and appended at the bottom', () async {
      await repo.createList('  Groceries ');
      await repo.createList('Hardware');
      final lists = await repo.getLists();
      expect([for (final l in lists) l.name], ['Groceries', 'Hardware']);
      expect([for (final l in lists) l.position], [0, 1]);
    });

    test('empty names are rejected', () {
      expect(() => repo.createList('   '), throwsArgumentError);
    });

    test(
      'duplicate names are rejected, ignoring case and whitespace',
      () async {
        await repo.createList('Äpfel');
        expect(await repo.listNameExists(' äpfel '), isTrue);
        expect(
          () => repo.createList('ÄPFEL '),
          throwsA(isA<DuplicateListNameException>()),
        );
        expect(await repo.getLists(), hasLength(1));
      },
    );

    test('reorder stores the new order', () async {
      final a = await repo.createList('A');
      final b = await repo.createList('B');
      final c = await repo.createList('C');
      await repo.reorderLists([c.id, a.id, b.id]);
      expect([for (final l in await repo.getLists()) l.name], ['C', 'A', 'B']);
      // New lists still go to the bottom.
      await repo.createList('D');
      expect(
        [for (final l in await repo.getLists()) l.name],
        ['C', 'A', 'B', 'D'],
      );
    });

    test('deleting a list removes its items but not the dictionary', () async {
      final list = await repo.createList('Groceries');
      await repo.addItem(list.id, 'Milk');
      await repo.deleteList(list.id);
      expect(await repo.getLists(), isEmpty);
      expect(await db.query('items'), isEmpty);
      expect(await DictionaryRepository(db).suggestions('mil'), ['Milk']);
      // A name becomes available again after its list is deleted.
      await repo.createList('Groceries');
    });
  });

  group('items', () {
    late int listId;

    setUp(() async => listId = (await repo.createList('Groceries')).id);

    test(
      'added items are trimmed, unstruck and go to the dictionary',
      () async {
        await repo.addItem(listId, '  Milk  ');
        final items = await repo.getItems(listId);
        expect(items.single.text, 'Milk');
        expect(items.single.struck, isFalse);
        expect(await DictionaryRepository(db).suggestions('milk'), ['Milk']);
      },
    );

    test('empty items are rejected', () {
      expect(() => repo.addItem(listId, ' \t '), throwsArgumentError);
    });

    test('containsItem ignores case and whitespace, struck or not', () async {
      final item = await repo.addItem(listId, 'Milk');
      expect(await repo.containsItem(listId, ' milk'), isTrue);
      await repo.setStruck(item.id, true);
      expect(await repo.containsItem(listId, 'MILK'), isTrue);
      expect(await repo.containsItem(listId, 'Bread'), isFalse);
    });

    test('a duplicate can be added as a second, unstruck item', () async {
      final first = await repo.addItem(listId, 'Milk');
      await repo.setStruck(first.id, true);
      await repo.addItem(listId, 'milk');
      final items = await repo.getItems(listId);
      expect(
        [for (final i in items) (i.text, i.struck)],
        [('Milk', true), ('milk', false)],
      );
    });

    test('strike and unstrike', () async {
      final item = await repo.addItem(listId, 'Milk');
      await repo.setStruck(item.id, true);
      expect((await repo.getItems(listId)).single.struck, isTrue);
      await repo.setStruck(item.id, false);
      expect((await repo.getItems(listId)).single.struck, isFalse);
    });

    test('broom removes only struck items of this list; undo restores them '
        'unchanged', () async {
      final other = (await repo.createList('Other')).id;
      final milk = await repo.addItem(listId, 'Milk');
      await repo.addItem(listId, 'Bread');
      final eggs = await repo.addItem(listId, 'Eggs');
      final otherItem = await repo.addItem(other, 'Nails');
      for (final id in [milk.id, eggs.id, otherItem.id]) {
        await repo.setStruck(id, true);
      }
      final before = await repo.getItems(listId);

      final removed = await repo.removeStruckItems(listId);
      expect([for (final i in removed) i.text], ['Milk', 'Eggs']);
      expect([for (final i in await repo.getItems(listId)) i.text], ['Bread']);
      expect(await repo.getItems(other), hasLength(1));

      await repo.restoreItems(removed);
      final after = await repo.getItems(listId);
      expect(
        [for (final i in after) i.toRow()],
        [for (final i in before) i.toRow()],
      );
    });
  });
}
