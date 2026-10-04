import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const _schemaVersion = 1;
const _fileName = 'shopper.db';

/// Opens the app database, creating or migrating the schema as needed.
///
/// Tests pass [factory] (sqflite_common_ffi) and [path]
/// (e.g. `inMemoryDatabasePath`).
Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
}) async {
  factory ??= databaseFactory;
  path ??= p.join(await factory.getDatabasesPath(), _fileName);
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: _schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    ),
  );
}

Future<void> _createSchema(Database db, int version) async {
  final batch = db.batch()
    // name_key: lower-cased, trimmed name; enforces unique list names
    // case-insensitively.
    ..execute('''
      CREATE TABLE lists (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        name_key    TEXT    NOT NULL UNIQUE,
        position    INTEGER NOT NULL,
        created_at  INTEGER NOT NULL
      )''')
    ..execute('''
      CREATE TABLE items (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id     INTEGER NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
        text        TEXT    NOT NULL,
        struck      INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL
      )''')
    ..execute('CREATE INDEX idx_items_list ON items(list_id)')
    // text_key: lower-cased, trimmed text; one dictionary entry per spelling
    // regardless of case. The first spelling entered is kept.
    ..execute('''
      CREATE TABLE dictionary (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        text        TEXT    NOT NULL,
        text_key    TEXT    NOT NULL UNIQUE,
        created_at  INTEGER NOT NULL
      )''');
  await batch.commit(noResult: true);
}
