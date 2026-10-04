import 'package:sqflite_common/sqlite_api.dart';
import '../database/app_database.dart';
import '../models/app_preferences.dart';

class SettingsRepository {
  final AppDatabase database;
  SettingsRepository(this.database);
  Future<AppPreferences> load(String accountId) async {
    final rows = await database.db.query(
      'app_settings',
      where: 'backend_url = ?',
      whereArgs: [accountId],
    );
    return AppPreferences({
      for (final row in rows)
        row['setting_key'] as String: row['setting_value'] as String,
    });
  }

  Future<void> set(String accountId, String key, String value) async {
    await database.db.insert('app_settings', {
      'backend_url': accountId,
      'setting_key': key,
      'setting_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
