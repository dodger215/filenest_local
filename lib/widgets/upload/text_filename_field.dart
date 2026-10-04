import 'package:flutter/material.dart';

class TextFilenameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  const TextFilenameField({
    super.key,
    required this.controller,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    decoration: const InputDecoration(
      labelText: 'Filename',
      hintText: 'Meeting notes',
      suffixText: '.txt',
    ),
  );
}
