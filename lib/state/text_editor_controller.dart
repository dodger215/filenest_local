import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../platform/file_picker_adapter.dart';
import '../services/text_file_service.dart';

class TextEditorController extends ChangeNotifier {
  final editor = QuillController.basic();
  final filename = TextEditingController(), caption = TextEditingController();
  TextEditorController() {
    editor.addListener(notifyListeners);
    filename.addListener(notifyListeners);
    caption.addListener(notifyListeners);
  }
  String get text => TextFileService.plainText(editor.document);
  int get characters => editor.document.toPlainText().trimRight().runes.length;
  int get words => editor.document.toPlainText().trim().isEmpty
      ? 0
      : editor.document.toPlainText().trim().split(RegExp(r'\s+')).length;
  bool get dirty =>
      text.trim().isNotEmpty ||
      filename.text.isNotEmpty ||
      caption.text.isNotEmpty;
  String? get validation {
    try {
      TextFileService.filename(filename.text);
      if (editor.document.toPlainText().trim().isEmpty)
        return 'Add some text before uploading.';
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  PickedUpload export() => PickedUpload(
    TextFileService.filename(filename.text),
    TextFileService.encode(editor.document),
    caption: caption.text.trim(),
  );
  @override
  void dispose() {
    editor.removeListener(notifyListeners);
    filename.removeListener(notifyListeners);
    caption.removeListener(notifyListeners);
    editor.dispose();
    filename.dispose();
    caption.dispose();
    super.dispose();
  }
}
