import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class TextEditorToolbar extends StatelessWidget {
  final QuillController controller;
  const TextEditorToolbar({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => QuillSimpleToolbar(
    controller: controller,
    config: const QuillSimpleToolbarConfig(
      multiRowsDisplay: false,
      toolbarSize: 48,
      showFontFamily: false,
      showFontSize: false,
      showColorButton: false,
      showBackgroundColorButton: false,
      showInlineCode: false,
      showCodeBlock: false,
      showListCheck: false,
      showSubscript: false,
      showSuperscript: false,
      showSearchButton: false,
      embedButtons: [],
    ),
  );
}
