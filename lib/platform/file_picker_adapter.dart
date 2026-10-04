import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

class PickedUpload {
  final String name;
  final Uint8List bytes;
  String caption;
  PickedUpload(this.name, this.bytes, {this.caption = ''});
}

class FilePickerAdapter {
  static const maxFileBytes = 100 * 1024 * 1024;
  static const maxBatchBytes = 250 * 1024 * 1024;
  Future<List<PickedUpload>> pick() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );
    if (result == null) return [];
    if (result.files.fold<int>(0, (n, f) => n + f.size) > maxBatchBytes)
      throw StateError('Choose up to 250 MB per batch.');
    final selected = <PickedUpload>[];
    for (final file in result.files) {
      _checkSize(file.size);
      var bytes = file.bytes;
      if (bytes == null && file.readStream != null) {
        final buffer = BytesBuilder(copy: false);
        await for (final List<int> chunk in file.readStream!) {
          _checkSize(buffer.length + chunk.length);
          buffer.add(chunk);
        }
        bytes = buffer.takeBytes();
      }
      if (bytes == null)
        throw StateError(
          'Could not read ${file.name}. Please choose it again.',
        );
      _checkSize(bytes.length);
      selected.add(PickedUpload(file.name, bytes));
    }
    return selected;
  }

  Future<List<PickedUpload>> fromDrop(List<XFile> files) async {
    var total = 0;
    for (final file in files) {
      final size = await file.length();
      _checkSize(size);
      total += size;
    }
    if (total > maxBatchBytes)
      throw StateError('Choose up to 250 MB per batch.');
    return [
      for (final file in files)
        PickedUpload(file.name, await file.readAsBytes()),
    ];
  }

  void _checkSize(int size) {
    if (size > maxFileBytes)
      throw StateError('Choose files smaller than 100 MB.');
  }
}
