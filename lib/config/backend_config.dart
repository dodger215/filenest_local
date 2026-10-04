import 'package:flutter/foundation.dart';

class BackendConfig {
  static const buildUrl = String.fromEnvironment('BACKEND_URL');
  static String get defaultUrl => buildUrl.isNotEmpty
      ? normalize(buildUrl)
      : kIsWeb
      ? normalize('${Uri.base.origin}/api')
      : 'http://localhost:3001';

  static String normalize(String value) {
    var input = value.trim();
    if (input.isEmpty)
      throw ArgumentError('Enter a backend URL or IP address.');
    if (!input.contains('://')) input = 'http://$input';
    final uri = Uri.tryParse(input);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        RegExp(r'\s').hasMatch(input)) {
      throw ArgumentError(
        'Use an HTTP or HTTPS URL, such as http://192.168.1.10:3001.',
      );
    }
    return uri.toString().replaceFirst(RegExp(r'/+$'), '');
  }
}
