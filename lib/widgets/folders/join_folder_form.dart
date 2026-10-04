import 'package:flutter/material.dart';
import 'folder_code_field.dart';

class JoinFolderForm extends StatelessWidget {
  final TextEditingController code, nickname;
  final bool save, ready, busy;
  final ValueChanged<bool> onSave;
  final VoidCallback onChanged, submit;
  const JoinFolderForm({
    super.key,
    required this.code,
    required this.nickname,
    required this.save,
    required this.ready,
    required this.busy,
    required this.onSave,
    required this.onChanged,
    required this.submit,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Enter the six-character code.'),
      const SizedBox(height: 20),
      FolderCodeField(
        controller: code,
        enabled: !busy,
        onChanged: onChanged,
        onSubmit: () {
          if (ready && !busy && code.text.trim().isNotEmpty) submit();
        },
      ),
      const SizedBox(height: 16),
      TextField(
        controller: nickname,
        enabled: !busy,
        decoration: const InputDecoration(
          labelText: 'Local folder nickname (optional)',
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Save this folder on this device'),
        value: save,
        onChanged: busy ? null : onSave,
      ),
      FilledButton.icon(
        onPressed: ready && !busy && code.text.trim().isNotEmpty
            ? submit
            : null,
        icon: const Icon(Icons.login),
        label: Text(busy ? 'Checking access…' : 'Join folder'),
      ),
    ],
  );
}
