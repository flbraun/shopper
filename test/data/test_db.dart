import 'package:shopper/data/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh in-memory database with the app schema.
Future<Database> openTestDatabase() {
  sqfliteFfiInit();
  return openAppDatabase(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
}

/// A clock that advances by one second per call, starting at 2026-01-01.
DateTime Function() steppingClock() {
  var t = DateTime(2026);
  return () => t = t.add(const Duration(seconds: 1));
}
