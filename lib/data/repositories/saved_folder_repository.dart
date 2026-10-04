import '../database/app_database.dart';
import '../models/saved_folder.dart';

class SavedFolderRepository {
  final AppDatabase database;
  SavedFolderRepository(this.database);
  Future<List<SavedFolder>> load(String accountId) async =>
      (await database.db.query(
        'saved_folders',
        where: 'backend_url = ?',
        whereArgs: [accountId],
        orderBy: 'is_pinned DESC, last_opened_at DESC',
      )).map(SavedFolder.fromMap).toList();
  Future<void> save(SavedFolder folder) => database.db.transaction((tx) async {
    final count = await tx.update(
      'saved_folders',
      folder.toMap(),
      where: 'backend_url = ? AND folder_id = ?',
      whereArgs: [folder.accountId, folder.folderId],
    );
    if (count == 0) await tx.insert('saved_folders', folder.toMap());
  });
  Future<void> remove(String accountId, String folderId) async {
    await database.db.delete(
      'saved_folders',
      where: 'backend_url = ? AND folder_id = ?',
      whereArgs: [accountId, folderId],
    );
  }
}
