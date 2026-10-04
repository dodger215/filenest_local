import 'package:sqflite_common/sqlite_api.dart';
import 'database_factory.dart';
import 'database_migrations.dart';

class AppDatabase {
  Database? _db;
  Database get db =>
      _db ?? (throw StateError('Local storage is not initialized.'));
  Future<void> initialize() async {
    if (_db != null) return;
    try {
      _db = await openLocalDatabase(
        OpenDatabaseOptions(
          version: DatabaseMigrations.version,
          onCreate: (db, version) => DatabaseMigrations.upgrade(db, 0, version),
          onUpgrade: DatabaseMigrations.upgrade,
        ),
      );
    } catch (e) {
      throw StateError(
        'Could not open local storage. Check available storage and browser SQLite setup. $e',
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
