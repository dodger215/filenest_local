import '../models/drive_directory.dart';
import 'backend_connection.dart';

class DriveDirectoryService {
  final BackendConnection connection;
  DriveDirectoryService(this.connection);
  DriveDirectory _parse(Map<String, dynamic> data) => DriveDirectory(
    code: data['code'] as String,
    folderId: data['folderId'] as String,
    createdAt: DateTime.parse(data['createdAt'] as String),
    ownedByMe: true,
  );
  Future<DriveDirectory?> findByCode(String code) async {
    try {
      return _parse(
        await connection.request(
          'GET',
          '/folders/code/${Uri.encodeComponent(code.trim().toUpperCase())}',
        ),
      );
    } on BackendException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<bool> codeExists(String code) async => await findByCode(code) != null;
  Future<DriveDirectory> getById(String id) async => _parse(
    await connection.request('GET', '/folders/${Uri.encodeComponent(id)}'),
  );
  Future<DriveDirectory> createDirectory() async =>
      _parse(await connection.request('POST', '/folders'));
  Future<DriveDirectory> requireDirectory(String code) async =>
      await findByCode(code) ??
      (throw StateError('Folder not found on this server.'));
}
