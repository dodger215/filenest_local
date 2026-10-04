import '../models/drive_file.dart';
import '../models/file_filter.dart';
import 'drive_directory_service.dart';
import 'backend_connection.dart';

class DriveFileService {
  final BackendConnection connection;
  final DriveDirectoryService directories;
  DriveFileService(this.connection, this.directories);
  DriveFileModel parse(Map<String, dynamic> data, String code) =>
      DriveFileModel.fromJson(
        data,
        code,
        connection.uri('/files/${data['id']}/content').toString(),
      );
  Future<List<DriveFileModel>> getFiles({
    required String directoryCode,
    FileFilter filter = const FileFilter(),
    String? folderId,
  }) async {
    if (filter.from != null &&
        filter.to != null &&
        filter.from!.isAfter(filter.to!))
      throw ArgumentError('from must be before or equal to to.');
    final id =
        folderId ??
        (await directories.requireDirectory(directoryCode)).folderId;
    final data = await connection.request(
      'GET',
      '/folders/${Uri.encodeComponent(id)}/files',
    );
    final extensions = filter.extensions
        .map((e) => e.toLowerCase().replaceFirst(RegExp(r'^\.'), ''))
        .toSet();
    final mimes = filter.mimeTypes.map((e) => e.toLowerCase()).toSet();
    return (data['files'] as List)
        .map((f) => parse(f as Map<String, dynamic>, directoryCode))
        .where(
          (f) =>
              (extensions.isEmpty || extensions.contains(f.extension)) &&
              (mimes.isEmpty || mimes.contains(f.mimeType.toLowerCase())) &&
              (filter.from == null ||
                  (f.createdAt != null &&
                      !f.createdAt!.isBefore(filter.from!))) &&
              (filter.to == null ||
                  (f.createdAt != null && !f.createdAt!.isAfter(filter.to!))),
        )
        .toList();
  }

  Future<DriveFileModel> getFile({
    required String directoryCode,
    required String fileId,
    String? folderId,
  }) async {
    final id =
        folderId ??
        (await directories.requireDirectory(directoryCode)).folderId;
    final data = await connection.request(
      'GET',
      '/files/${Uri.encodeComponent(fileId)}',
    );
    if (data['folderId'] != id)
      throw StateError('File is not inside this directory.');
    return parse(data, directoryCode);
  }

  Future<void> trashFile({
    required String directoryCode,
    required String fileId,
    String? folderId,
  }) async {
    final id =
        folderId ??
        (await directories.requireDirectory(directoryCode)).folderId;
    await connection.request(
      'DELETE',
      '/folders/${Uri.encodeComponent(id)}/files/${Uri.encodeComponent(fileId)}',
    );
  }
}
