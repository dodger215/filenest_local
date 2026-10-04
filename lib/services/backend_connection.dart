import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';

class BackendException implements Exception {
  final int status;
  final String message;
  BackendException(this.status, this.message);
  @override
  String toString() => message;
}

class BackendConnection {
  final http.Client client;
  String _baseUrl;
  BackendConnection({String? baseUrl, http.Client? client})
    : _baseUrl = BackendConfig.normalize(baseUrl ?? BackendConfig.defaultUrl),
      client = client ?? http.Client();
  String get baseUrl => _baseUrl;
  set baseUrl(String value) => _baseUrl = BackendConfig.normalize(value);
  Uri uri(String path) =>
      Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}');
  Future<Map<String, dynamic>> request(String method, String path) async {
    final response = await client
        .send(http.Request(method, uri(path)))
        .timeout(const Duration(seconds: 20));
    return decode(
      await http.Response.fromStream(
        response,
      ).timeout(const Duration(seconds: 20)),
    );
  }

  Map<String, dynamic> decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(
        response.statusCode,
        body is Map
            ? (body['error']?.toString() ?? 'Server request failed.')
            : 'Server request failed (${response.statusCode}). Check the backend URL.',
      );
    }
    if (body is! Map<String, dynamic>)
      throw StateError(
        'The backend returned an invalid response. Check its URL.',
      );
    return body;
  }

  Future<void> checkHealth() async {
    final result = await request('GET', '/health');
    if (result['status'] != 'ok' || result['storage'] != 'sqlite')
      throw StateError('This is not a FileNest storage server.');
  }

  Future<void> dispose() async => client.close();
}
