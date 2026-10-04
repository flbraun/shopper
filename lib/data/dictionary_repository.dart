import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Every item text ever added. Entries are never removed.
class DictionaryRepository {
  DictionaryRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DatabaseExecutor _db;
  final DateTime Function() _clock;

  static const suggestionLimit = 8;

  /// Adds [text] unless an entry with the same text (ignoring case and
  /// surrounding whitespace) already exists.
  Future<void> add(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _db.insert('dictionary', {
      'text': trimmed,
      'text_key': textKey(trimmed),
      'created_at': _clock().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Entries containing [query] (case-insensitive). Entries starting with
  /// [query] come first; each group is sorted alphabetically.
  Future<List<String>> suggestions(String query) async {
    final key = textKey(query);
    if (key.isEmpty) return const [];
    final escaped = _escapeLike(key);
    final rows = await _db.rawQuery(
      r'''
      SELECT text FROM dictionary
      WHERE text_key LIKE ? ESCAPE '\'
      ORDER BY CASE WHEN text_key LIKE ? ESCAPE '\' THEN 0 ELSE 1 END,
               text_key
      LIMIT ?''',
      ['%$escaped%', '$escaped%', suggestionLimit],
    );
    return [for (final row in rows) row['text']! as String];
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
