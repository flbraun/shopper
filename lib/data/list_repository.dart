import 'package:sqflite/sqflite.dart';

import 'dictionary_repository.dart';
import 'models.dart';

/// Thrown when creating a list whose name is already taken
/// (ignoring case and surrounding whitespace).
class DuplicateListNameException implements Exception {
  const DuplicateListNameException(this.name);

  final String name;

  @override
  String toString() => 'DuplicateListNameException: $name';
}

/// Shopping lists and their items.
class ListRepository {
  ListRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Database _db;
  final DateTime Function() _clock;

  // Lists

  /// All lists in title-screen order.
  Future<List<ShoppingList>> getLists() async {
    final rows = await _db.query('lists', orderBy: 'position, id');
    return rows.map(ShoppingList.fromRow).toList();
  }

  Future<bool> listNameExists(String name) async {
    final rows = await _db.query(
      'lists',
      columns: ['id'],
      where: 'name_key = ?',
      whereArgs: [textKey(name)],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Creates a list with the trimmed [name], appended after the last list.
  ///
  /// Throws [ArgumentError] for an empty name and
  /// [DuplicateListNameException] if the name is taken.
  Future<ShoppingList> createList(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    return _db.transaction((txn) async {
      final maxRow = await txn.rawQuery(
        'SELECT COALESCE(MAX(position), -1) AS max FROM lists',
      );
      final position = (maxRow.first['max']! as int) + 1;
      final createdAt = _clock();
      try {
        final id = await txn.insert('lists', {
          'name': trimmed,
          'name_key': textKey(trimmed),
          'position': position,
          'created_at': createdAt.millisecondsSinceEpoch,
        });
        return ShoppingList(
          id: id,
          name: trimmed,
          position: position,
          createdAt: createdAt,
        );
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          throw DuplicateListNameException(trimmed);
        }
        rethrow;
      }
    });
  }

  /// Deletes the list and all of its items. The dictionary is not touched.
  Future<void> deleteList(int listId) async {
    await _db.delete('lists', where: 'id = ?', whereArgs: [listId]);
  }

  /// Stores a new title-screen order. [listIds] contains all list ids in
  /// their new order.
  Future<void> reorderLists(List<int> listIds) async {
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < listIds.length; i++) {
        batch.update(
          'lists',
          {'position': i},
          where: 'id = ?',
          whereArgs: [listIds[i]],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // Items

  /// All items of a list, unsorted (see `sortItems`).
  Future<List<Item>> getItems(int listId) async {
    final rows = await _db.query(
      'items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'id',
    );
    return rows.map(Item.fromRow).toList();
  }

  /// Whether the list already has an item with this text
  /// (ignoring case and surrounding whitespace), struck or not.
  Future<bool> containsItem(int listId, String text) async {
    final key = textKey(text);
    final items = await getItems(listId);
    return items.any((item) => textKey(item.text) == key);
  }

  /// Adds an unstruck item with the trimmed [text] and records the text in
  /// the dictionary. Duplicates are not checked here; see [containsItem].
  ///
  /// Throws [ArgumentError] for empty text.
  Future<Item> addItem(int listId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    return _db.transaction((txn) async {
      final createdAt = _clock();
      final id = await txn.insert('items', {
        'list_id': listId,
        'text': trimmed,
        'struck': 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      });
      await DictionaryRepository(txn, clock: _clock).add(trimmed);
      return Item(
        id: id,
        listId: listId,
        text: trimmed,
        struck: false,
        createdAt: createdAt,
      );
    });
  }

  Future<void> setStruck(int itemId, bool struck) async {
    await _db.update(
      'items',
      {'struck': struck ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Deletes all struck items of the list and returns them, so they can be
  /// put back with [restoreItems].
  Future<List<Item>> removeStruckItems(int listId) async {
    return _db.transaction((txn) async {
      final rows = await txn.query(
        'items',
        where: 'list_id = ? AND struck = 1',
        whereArgs: [listId],
      );
      await txn.delete(
        'items',
        where: 'list_id = ? AND struck = 1',
        whereArgs: [listId],
      );
      return rows.map(Item.fromRow).toList();
    });
  }

  /// Re-inserts items removed by [removeStruckItems], unchanged (same id,
  /// text, struck state and creation time).
  Future<void> restoreItems(List<Item> items) async {
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        batch.insert('items', item.toRow());
      }
      await batch.commit(noResult: true);
    });
  }
}
