import 'package:flutter_test/flutter_test.dart';
import 'package:shopper/data/dictionary_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_db.dart';

void main() {
  late Database db;
  late DictionaryRepository dict;

  setUp(() async {
    db = await openTestDatabase();
    dict = DictionaryRepository(db, clock: steppingClock());
  });

  tearDown(() => db.close());

  test('contains matching is case-insensitive, prefix matches first', () async {
    for (final t in ['Oat milk', 'Milk', 'Buttermilk', 'Milka', 'Bread']) {
      await dict.add(t);
    }
    expect(await dict.suggestions('MIL'), [
      'Milk',
      'Milka',
      'Buttermilk',
      'Oat milk',
    ]);
  });

  test('non-ASCII letters match case-insensitively', () async {
    await dict.add('Äpfel');
    expect(await dict.suggestions('äpf'), ['Äpfel']);
    expect(await dict.suggestions('ÄPF'), ['Äpfel']);
  });

  test('one entry per text ignoring case; first spelling is kept', () async {
    await dict.add('Milk');
    await dict.add(' milk ');
    expect(await dict.suggestions('milk'), ['Milk']);
  });

  test('empty query returns nothing; empty text is not stored', () async {
    await dict.add('   ');
    await dict.add('Milk');
    expect(await dict.suggestions('  '), isEmpty);
    expect(await db.query('dictionary'), hasLength(1));
  });

  test('LIKE wildcards in the query are matched literally', () async {
    await dict.add('100% juice');
    await dict.add('1000 g flour');
    await dict.add('a_b');
    await dict.add('axb');
    expect(await dict.suggestions('100%'), ['100% juice']);
    expect(await dict.suggestions('a_'), ['a_b']);
  });

  test('suggestions are capped', () async {
    for (var i = 0; i < 20; i++) {
      await dict.add('item $i');
    }
    expect(
      await dict.suggestions('item'),
      hasLength(DictionaryRepository.suggestionLimit),
    );
  });
}
