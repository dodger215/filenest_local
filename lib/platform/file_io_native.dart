import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Uint8List> readLocalFile(String path) => File(path).readAsBytes();
Future<String> saveDownload(String name, Stream<List<int>> stream) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = await Directory(
    p.join(base.path, 'filenest_downloads'),
  ).create(recursive: true);
  final unique = await dir.createTemp('file_');
  name = p.basename(name).replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
  if (name.isEmpty || name == '.' || name == '..') name = 'download';
  final output = File(p.join(unique.path, name));
  final partial = File('${output.path}.part');
  final sink = partial.openWrite();
  try {
    await sink.addStream(stream);
    await sink.flush();
    await sink.close();
    await partial.rename(output.path);
    return output.path;
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {}
    await unique.delete(recursive: true);
    rethrow;
  }
}
