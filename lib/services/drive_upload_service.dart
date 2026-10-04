import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../models/drive_file.dart';
import '../models/file_upload_request.dart';
import '../platform/file_io.dart';
import 'drive_directory_service.dart';
import 'backend_connection.dart';

class DriveUploadService {
  final BackendConnection connection;
  final DriveDirectoryService directories;
  DriveUploadService(this.connection, this.directories);
  Future<DriveFileModel> upload(FileUploadRequest request) async {
    final folder = await directories.requireDirectory(request.directoryCode);
    return uploadBytes(
      folderId: folder.folderId,
      code: folder.code,
      name: path.basename(request.filePath),
      bytes: await readLocalFile(request.filePath),
      caption: request.caption,
    );
  }

  Future<String> reserveId() async {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<DriveFileModel> uploadBytes({
    required String folderId,
    required String code,
    required String name,
    required Uint8List bytes,
    String? caption,
    String? mimeType,
    String? uploadId,
    String? category,
    void Function(int, int)? onProgress,
  }) async {
    final mime = mimeType ?? lookupMimeType(name) ?? 'application/octet-stream';
    Stream<List<int>> chunks() async* {
      for (var offset = 0; offset < bytes.length; offset += 65536) {
        final end = (offset + 65536).clamp(0, bytes.length);
        yield bytes.sublist(offset, end);
        onProgress?.call(end, bytes.length);
      }
    }

    final request = http.MultipartRequest(
      'POST',
      connection.uri('/folders/${Uri.encodeComponent(folderId)}/files'),
    );
    request.fields.addAll({
      'uploadId': uploadId ?? await reserveId(),
      'name': name,
      if (caption != null) 'caption': caption,
      if (category != null) 'category': category,
    });
    request.files.add(
      http.MultipartFile(
        'file',
        chunks(),
        bytes.length,
        filename: name,
        contentType: MediaType.parse(mime),
      ),
    );
    final response = await connection.client
        .send(request)
        .timeout(const Duration(minutes: 10));
    final data = connection.decode(
      await http.Response.fromStream(
        response,
      ).timeout(const Duration(seconds: 30)),
    );
    return DriveFileModel.fromJson(
      data,
      code,
      connection.uri('/files/${data['id']}/content').toString(),
    );
  }
}
