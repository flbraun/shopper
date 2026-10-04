import 'package:flutter_test/flutter_test.dart';
import 'package:shopper/data/item_sorting.dart';
import 'package:shopper/data/models.dart';

Item _item(int id, String text, {bool struck = false, int? addedAt}) => Item(
  id: id,
  listId: 1,
  text: text,
  struck: struck,
  createdAt: DateTime.fromMillisecondsSinceEpoch(addedAt ?? id),
);

List<String> _texts(List<Item> items) => [for (final i in items) i.text];

void main() {
  final items = [
    _item(1, 'milk', addedAt: 30),
    _item(2, 'Bread', struck: true, addedAt: 10),
    _item(3, 'apples', addedAt: 40),
    _item(4, 'Coffee', struck: true, addedAt: 20),
  ];

  group('in place', () {
    const p = StruckPlacement.inPlace;

    test('A-Z is case-insensitive', () {
      expect(_texts(sortItems(items, ItemOrder.az, p)), [
        'apples',
        'Bread',
        'Coffee',
        'milk',
      ]);
    });

    test('Z-A', () {
      expect(_texts(sortItems(items, ItemOrder.za, p)), [
        'milk',
        'Coffee',
        'Bread',
        'apples',
      ]);
    });

    test('added earliest / latest', () {
      expect(_texts(sortItems(items, ItemOrder.addedEarliest, p)), [
        'Bread',
        'Coffee',
        'milk',
        'apples',
      ]);
      expect(_texts(sortItems(items, ItemOrder.addedLatest, p)), [
        'apples',
        'milk',
        'Coffee',
        'Bread',
      ]);
    });
  });

  group('move to bottom', () {
    const p = StruckPlacement.moveToBottom;

    test('struck items follow unstruck ones, each group sorted', () {
      expect(_texts(sortItems(items, ItemOrder.az, p)), [
        'apples',
        'milk',
        'Bread',
        'Coffee',
      ]);
      expect(_texts(sortItems(items, ItemOrder.za, p)), [
        'milk',
        'apples',
        'Coffee',
        'Bread',
      ]);
      expect(_texts(sortItems(items, ItemOrder.addedLatest, p)), [
        'apples',
        'milk',
        'Coffee',
        'Bread',
      ]);
    });
  });

  test('umlauts sort next to their base letter', () {
    final german = [
      _item(1, 'Zucker'),
      _item(2, 'Äpfel'),
      _item(3, 'Apfelsaft'),
      _item(4, 'Öl'),
      _item(5, 'Nudeln'),
    ];
    expect(_texts(sortItems(german, ItemOrder.az, StruckPlacement.inPlace)), [
      'Äpfel',
      'Apfelsaft',
      'Nudeln',
      'Öl',
      'Zucker',
    ]);
  });

  test('equal texts and timestamps fall back to id', () {
    final same = [_item(2, 'eggs', addedAt: 5), _item(1, 'eggs', addedAt: 5)];
    for (final order in ItemOrder.values) {
      expect(
        [for (final i in sortItems(same, order, StruckPlacement.inPlace)) i.id],
        [1, 2],
      );
    }
  });
}
