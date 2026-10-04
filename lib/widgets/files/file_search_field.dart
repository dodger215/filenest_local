import 'package:flutter/material.dart';

class FileSearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const FileSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  State<FileSearchField> createState() => _FileSearchFieldState();
}

class _FileSearchFieldState extends State<FileSearchField> {
  late final input = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(FileSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (input.text != widget.value) input.text = widget.value;
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: input,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      hintText: 'Search filename or caption',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: input.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                input.clear();
                widget.onChanged('');
              },
              icon: const Icon(Icons.close),
            ),
    ),
  );
}
