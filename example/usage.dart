import 'package:drive_rooms_flutter/drive_rooms.dart';

Future<void> example(String backendUrl, String filePath) async {
  final connection = BackendConnection(baseUrl: backendUrl);
  try {
    await connection.checkHealth();
    final directories = DriveDirectoryService(connection);
    final folder = await directories.createDirectory();
    final upload = DriveUploadService(connection, directories);
    await upload.upload(
      FileUploadRequest(
        directoryCode: folder.code,
        filePath: filePath,
        caption: 'Shared from this device',
      ),
    );
    final files = DriveFileService(connection, directories);
    await files.getFiles(directoryCode: folder.code);
  } finally {
    await connection.dispose();
  }
}
