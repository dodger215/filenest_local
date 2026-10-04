import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../platform/file_io.dart';
import 'drive_file_service.dart';
import 'backend_connection.dart';

class DriveDownloadService {
  final BackendConnection connection;
  final DriveFileService files;
  DriveDownloadService(this.connection, this.files);
  Future<http.StreamedResponse> _content(String id) async {
    final response = await connection.client
        .send(
          http.Request(
            'GET',
            connection.uri('/files/${Uri.encodeComponent(id)}/content'),
          ),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200)
      connection.decode(await http.Response.fromStream(response));
    return response;
  }

  Future<String> download({
    required String directoryCode,
    required String fileId,
    String? folderId,
    void Function(int, int?)? onProgress,
  }) async {
    final file = await files.getFile(
      directoryCode: directoryCode,
      fileId: fileId,
      folderId: folderId,
    );
    final response = await _content(fileId);
    var received = 0;
    return saveDownload(
      file.name,
      response.stream.timeout(const Duration(seconds: 60)).map((chunk) {
        received += chunk.length;
        onProgress?.call(received, file.size);
        return chunk;
      }),
    );
  }

  Future<Uint8List> previewImage({
    required String folderId,
    required String code,
    required String fileId,
  }) async {
    final file = await files.getFile(
      directoryCode: code,
      fileId: fileId,
      folderId: folderId,
    );
    if (!file.mimeType.startsWith('image/'))
      throw StateError('This file is not an image.');
    if ((file.size ?? 0) > 20 * 1024 * 1024)
      throw StateError('Download images larger than 20 MB to preview them.');
    final response = await _content(fileId);
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 60),
    )) {
      if (buffer.length + chunk.length > 20 * 1024 * 1024)
        throw StateError('Image preview exceeds 20 MB.');
      buffer.add(chunk);
    }
    return buffer.takeBytes();
  }
}
