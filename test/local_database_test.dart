import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:drive_rooms_flutter/data/database/app_database.dart';
import 'package:drive_rooms_flutter/data/database/database_migrations.dart';
import 'package:drive_rooms_flutter/data/repositories/settings_repository.dart';
import 'package:drive_rooms_flutter/data/repositories/saved_folder_repository.dart';
import 'package:drive_rooms_flutter/data/models/saved_folder.dart';
import 'package:drive_rooms_flutter/state/drive_ui_controller.dart';
import 'package:drive_rooms_flutter/services/backend_connection.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryDatabase extends AppDatabase {
  final Database storage;
  MemoryDatabase(this.storage);
  @override
  Database get db => storage;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test('schema migration retains existing saved folders', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    // Existing v1 schema and user data.
    await db.execute(
      "CREATE TABLE saved_folders (id INTEGER PRIMARY KEY, google_account_id TEXT, drive_folder_id TEXT, folder_code TEXT, local_nickname TEXT, owner_email TEXT, cached_role TEXT, is_pinned INTEGER, notifications_enabled INTEGER, created_at TEXT, last_opened_at TEXT, last_validated_at TEXT)",
    );
    await db.execute(
      'CREATE TABLE app_settings (google_account_id TEXT, setting_key TEXT, setting_value TEXT)',
    );
    await db.insert('saved_folders', {
      'id': 1,
      'google_account_id': 'legacy',
      'drive_folder_id': 'old-folder',
      'folder_code': 'ABC234',
      'local_nickname': 'My files',
      'is_pinned': 1,
      'notifications_enabled': 0,
      'created_at': '2026-01-01T00:00:00Z',
    });
    await db.insert('app_settings', {
      'google_account_id': 'legacy',
      'setting_key': 'theme',
      'setting_value': 'dark',
    });
    await DatabaseMigrations.upgrade(db, 1, 2);
    final row = (await db.query('saved_folders')).single;
    expect(row['backend_url'], 'legacy');
    expect(row['folder_id'], 'old-folder');
    expect(row['local_nickname'], 'My files');
    expect(row['is_pinned'], 1);
    expect((await db.query('app_settings')).single['setting_value'], 'dark');
    await db.close();
  });
  test(
    'backend override persists and switching isolates saved folders',
    () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseMigrations.version,
          onCreate: (db, version) => DatabaseMigrations.upgrade(db, 0, version),
        ),
      );
      final local = MemoryDatabase(db);
      final settings = SettingsRepository(local);
      await settings.set('device', 'backend_url', 'http://first:3001');
      final repository = SavedFolderRepository(local);
      await repository.save(
        SavedFolder(
          accountId: 'http://first:3001',
          folderId: 'one',
          code: 'ABC234',
          createdAt: DateTime.now(),
        ),
      );
      final controller = DriveUiController(
        database: local,
        connection: BackendConnection(
          baseUrl: 'http://build-default:3001',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );
      await controller.initialize();
      expect(controller.state.initializationError, null);
      expect(controller.connection.baseUrl, 'http://first:3001');
      expect(controller.saved.folders.single.folderId, 'one');
      await controller.setBackendUrl('second:3001/');
      expect(controller.saved.folders, isEmpty);
      expect(
        (await settings.load('device')).values['backend_url'],
        'http://second:3001',
      );
      await controller.setBackendUrl('http://first:3001');
      expect(controller.saved.folders.single.folderId, 'one');
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      await db.close();
    },
  );
  test(
    'an offline saved folder can be retried when its server returns',
    () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseMigrations.version,
          onCreate: (db, version) => DatabaseMigrations.upgrade(db, 0, version),
        ),
      );
      final local = MemoryDatabase(db);
      var online = false;
      final connection = BackendConnection(
        baseUrl: 'http://local:3001',
        client: MockClient((request) async {
          if (!online) return http.Response('{"error":"Server offline"}', 503);
          return http.Response(
            request.url.path.endsWith('/files')
                ? '{"files":[]}'
                : '{"folderId":"one","code":"ABC234","createdAt":"2026-01-01T00:00:00Z"}',
            200,
          );
        }),
      );
      final controller = DriveUiController(
        database: local,
        connection: connection,
      );
      await controller.initialize();
      final record = SavedFolder(
        accountId: connection.baseUrl,
        folderId: 'one',
        code: 'ABC234',
        createdAt: DateTime.now(),
      );
      await controller.openFolder(record);
      expect(controller.state.error, contains('Server offline'));
      online = true;
      await controller.retryFolder();
      expect(controller.state.error, null);
      expect(controller.state.activeFolder?.folderId, 'one');
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      await db.close();
    },
  );
}
