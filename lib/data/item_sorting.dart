import 'models.dart';

/// How items of a list are ordered.
enum ItemOrder { az, za, addedEarliest, addedLatest }

/// Where struck items go.
enum StruckPlacement { inPlace, moveToBottom }

/// Returns [items] in display order.
///
/// With [StruckPlacement.moveToBottom], unstruck items come first and struck
/// items follow; both groups are sorted by [order].
List<Item> sortItems(
  Iterable<Item> items,
  ItemOrder order,
  StruckPlacement placement,
) {
  int compare(Item a, Item b) {
    if (placement == StruckPlacement.moveToBottom && a.struck != b.struck) {
      return a.struck ? 1 : -1;
    }
    final result = switch (order) {
      ItemOrder.az => _compareText(a, b),
      ItemOrder.za => _compareText(b, a),
      ItemOrder.addedEarliest => _compareAdded(a, b),
      ItemOrder.addedLatest => _compareAdded(b, a),
    };
    // Stable, deterministic result for equal keys.
    return result != 0 ? result : a.id.compareTo(b.id);
  }

  return items.toList()..sort(compare);
}

int _compareText(Item a, Item b) {
  final result = _collationKey(a.text).compareTo(_collationKey(b.text));
  if (result != 0) return result;
  return a.text.toLowerCase().compareTo(b.text.toLowerCase());
}

int _compareAdded(Item a, Item b) => a.createdAt.compareTo(b.createdAt);

/// Case-insensitive sort key that orders letters with diacritics next to
/// their base letter (German dictionary order: "Äpfel" sorts with "Apfel",
/// not after "Zucker"). Dart has no built-in locale collation.
String _collationKey(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_foldedLetters[char] ?? char);
  }
  return buffer.toString();
}

const _foldedLetters = {
  'ä': 'a', 'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', //
  'ç': 'c', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ñ': 'n', //
  'ö': 'o', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o', //
  'ß': 'ss', //
  'ü': 'u', 'ù': 'u', 'ú': 'u', 'û': 'u', //
  'ý': 'y', 'ÿ': 'y',
};
