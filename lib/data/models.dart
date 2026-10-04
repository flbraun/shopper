/// A shopping list as shown on the title screen.
class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.position,
    required this.createdAt,
  });

  factory ShoppingList.fromRow(Map<String, Object?> row) => ShoppingList(
    id: row['id']! as int,
    name: row['name']! as String,
    position: row['position']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
  );

  final int id;
  final String name;

  /// Order on the title screen, ascending.
  final int position;
  final DateTime createdAt;
}

/// A single entry of a shopping list. Items are plain strings.
class Item {
  const Item({
    required this.id,
    required this.listId,
    required this.text,
    required this.struck,
    required this.createdAt,
  });

  factory Item.fromRow(Map<String, Object?> row) => Item(
    id: row['id']! as int,
    listId: row['list_id']! as int,
    text: row['text']! as String,
    struck: row['struck'] == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
  );

  final int id;
  final int listId;
  final String text;
  final bool struck;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
    'id': id,
    'list_id': listId,
    'text': text,
    'struck': struck ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };
}

/// Case-insensitive comparison key for list names, item texts and dictionary
/// entries. Dart's toLowerCase() handles non-ASCII letters (Ä/ä, Ö/ö, …),
/// which SQLite's NOCASE collation does not.
String textKey(String text) => text.trim().toLowerCase();
