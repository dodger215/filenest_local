import 'package:flutter/material.dart';

class FolderNicknameDialog extends StatefulWidget {
  final String nickname;
  const FolderNicknameDialog({super.key, required this.nickname});
  @override
  State<FolderNicknameDialog> createState() => _FolderNicknameDialogState();
}

class _FolderNicknameDialogState extends State<FolderNicknameDialog> {
  late final input = TextEditingController(text: widget.nickname);
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Local folder nickname'),
    content: TextField(
      controller: input,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Nickname'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, input.text.trim()),
        child: const Text('Save'),
      ),
    ],
  );
}
