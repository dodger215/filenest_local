import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:drive_rooms_flutter/drive_rooms.dart';

void main() {
  test('backend URL supports LAN addresses and rejects invalid settings', () {
    expect(
      BackendConfig.normalize(' 192.168.1.10:3001/ '),
      'http://192.168.1.10:3001',
    );
    expect(
      BackendConfig.normalize('https://files.example.com/api/'),
      'https://files.example.com/api',
    );
    for (final url in [
      '',
      'ftp://host',
      'http://user:secret@host',
      'http://host?q=1',
      'http://bad host',
    ]) {
      expect(() => BackendConfig.normalize(url), throwsArgumentError);
    }
  });
  test(
    'directory lookup normalizes code, preserves API prefix, and sends no authentication',
    () async {
      final connection = BackendConnection(
        baseUrl: 'http://localhost:3001/api',
        client: MockClient((request) async {
          expect(request.url.path, '/api/folders/code/ABC234');
          expect(request.headers.containsKey('authorization'), false);
          return http.Response(
            jsonEncode({
              'folderId': 'folder',
              'code': 'ABC234',
              'createdAt': '2026-01-01T00:00:00Z',
            }),
            200,
          );
        }),
      );
      final result = await DriveDirectoryService(
        connection,
      ).requireDirectory(' abc234 ');
      expect(result.folderId, 'folder');
      await connection.dispose();
    },
  );
  test('missing folder differs from server failure', () async {
    var status = 404;
    final connection = BackendConnection(
      client: MockClient(
        (_) async => http.Response('{"error":"server error"}', status),
      ),
    );
    final directories = DriveDirectoryService(connection);
    expect(await directories.findByCode('ABC234'), null);
    status = 500;
    await expectLater(
      directories.findByCode('ABC234'),
      throwsA(isA<BackendException>()),
    );
    await connection.dispose();
  });
  test(
    'file filtering preserves metadata and enforces folder membership',
    () async {
      final connection = BackendConnection(
        baseUrl: 'http://localhost:3001/api',
        client: MockClient((request) async {
          final file = {
            'id': 'f1',
            'folderId': 'one',
            'name': 'notes.txt',
            'caption': 'Caption',
            'mimeType': 'text/plain',
            'category': 'documents',
            'size': 3,
            'path': 'uploads/one/documents/f1',
            'createdAt': '2026-01-01T00:00:00Z',
          };
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/files')
                  ? {
                      'files': [file],
                    }
                  : file,
            ),
            200,
          );
        }),
      );
      final files = DriveFileService(
        connection,
        DriveDirectoryService(connection),
      );
      final results = await files.getFiles(
        directoryCode: 'ABC234',
        folderId: 'one',
        filter: const FileFilter(extensions: {'.TXT'}),
      );
      expect(results.single.storagePath, 'uploads/one/documents/f1');
      expect(
        results.single.webViewLink,
        'http://localhost:3001/api/files/f1/content',
      );
      expect(results.single.category, 'documents');
      await expectLater(
        files.getFile(directoryCode: 'ABC234', fileId: 'f1', folderId: 'two'),
        throwsStateError,
      );
      await connection.dispose();
    },
  );
  test(
    'upload uses multipart with stable retry ID, filename, caption and category',
    () async {
      final connection = BackendConnection(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/folders/one/files');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          final body = request.body;
          for (final value in [
            'retry-id-123456789',
            'note.txt',
            'My caption',
            'documents',
            'hello',
          ]) {
            expect(body, contains(value));
          }
          return http.Response(
            jsonEncode({
              'id': 'f1',
              'name': 'note.txt',
              'mimeType': 'text/plain',
              'path': 'uploads/one/documents/f1',
            }),
            201,
          );
        }),
      );
      final uploads = DriveUploadService(
        connection,
        DriveDirectoryService(connection),
      );
      final file = await uploads.uploadBytes(
        folderId: 'one',
        code: 'ABC234',
        name: 'note.txt',
        bytes: Uint8List.fromList(utf8.encode('hello')),
        caption: 'My caption',
        category: 'documents',
        uploadId: 'retry-id-123456789',
      );
      expect(file.storagePath, 'uploads/one/documents/f1');
      await connection.dispose();
    },
  );
}
