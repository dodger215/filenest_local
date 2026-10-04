import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_quill/flutter_quill.dart';

class TextFileService {
  static String filename(String input) {
    var name = input.trim();
    if (name.isEmpty || RegExp(r'[/\\\x00-\x1F]').hasMatch(name))
      throw const FormatException('Enter a filename without path separators.');
    while (name.toLowerCase().endsWith('.txt')) {
      name = name.substring(0, name.length - 4).trim();
    }
    if (name.isEmpty || name == '.' || name == '..')
      throw const FormatException('Enter a filename.');
    return '$name.txt';
  }

  static String plainText(Document document) {
    final output = StringBuffer();
    var line = StringBuffer();
    var listNumber = 0;
    for (final op in document.toDelta().toJson()) {
      final data = op['insert'];
      if (data is! String)
        continue; // Embedded media never becomes misleading TXT data.
      final attrs = op['attributes'] as Map? ?? const {};
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        line.write(part);
        final link = attrs['link'];
        if (link is String && part.isNotEmpty && part != link)
          line.write(' ($link)');
        if (i < parts.length - 1) {
          final list = attrs['list'];
          if (list == 'ordered') {
            listNumber++;
          } else {
            listNumber = 0;
          }
          final prefix = switch (list) {
            'ordered' => '$listNumber. ',
            'bullet' => '- ',
            'checked' => '[x] ',
            'unchecked' => '[ ] ',
            _ => attrs['blockquote'] == true ? '> ' : '',
          };
          output.write('$prefix$line\n');
          line = StringBuffer();
        }
      }
    }
    if (line.isNotEmpty) output.write(line);
    return output.toString();
  }

  static Uint8List encode(Document document) {
    final text = plainText(document);
    if (document.toPlainText().trim().isEmpty)
      throw const FormatException('Add some text before uploading.');
    return Uint8List.fromList(utf8.encode(text));
  }
}
