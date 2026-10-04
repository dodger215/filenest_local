import 'package:sqflite_common/sqlite_api.dart';

class DatabaseMigrations {
  static const version = 2;
  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= 2) return;
    if (oldVersion == 1) {
      // Table rebuilds also work on older Android SQLite versions.
      await db.execute(
        'ALTER TABLE saved_folders RENAME TO legacy_saved_folders',
      );
      await db.execute(
        'ALTER TABLE app_settings RENAME TO legacy_app_settings',
      );
    }
    await db.execute('''
      CREATE TABLE saved_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backend_url TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        folder_code TEXT NOT NULL,
        local_nickname TEXT NOT NULL DEFAULT '',
        owner_email TEXT,
        cached_role TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_opened_at TEXT,
        last_validated_at TEXT,
        UNIQUE(backend_url, folder_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE app_settings (
        backend_url TEXT NOT NULL,
        setting_key TEXT NOT NULL,
        setting_value TEXT NOT NULL,
        PRIMARY KEY(backend_url, setting_key)
      )
    ''');
    if (oldVersion == 1) {
      await db.execute('''
        INSERT INTO saved_folders
        SELECT id, google_account_id, drive_folder_id, folder_code,
          local_nickname, owner_email, cached_role, is_pinned,
          notifications_enabled, created_at, last_opened_at, last_validated_at
        FROM legacy_saved_folders
      ''');
      await db.execute('''
        INSERT INTO app_settings
        SELECT google_account_id, setting_key, setting_value FROM legacy_app_settings
      ''');
      await db.execute('DROP TABLE legacy_saved_folders');
      await db.execute('DROP TABLE legacy_app_settings');
    }
  }
}
