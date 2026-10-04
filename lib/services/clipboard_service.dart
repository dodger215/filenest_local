import 'package:flutter/services.dart';

class ClipboardService {
  static Future<void> copy(String value) =>
      Clipboard.setData(ClipboardData(text: value));
  static Future<String> paste() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
}
