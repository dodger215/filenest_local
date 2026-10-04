import 'package:flutter/material.dart';

class CreateFolderForm extends StatelessWidget {
  final TextEditingController nickname;
  final bool ready, busy;
  final VoidCallback submit;
  const CreateFolderForm({
    super.key,
    required this.nickname,
    required this.ready,
    required this.busy,
    required this.submit,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Create your shared folder',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text('Generate a code and start sharing files.'),
      const SizedBox(height: 20),
      TextField(
        controller: nickname,
        enabled: !busy,
        decoration: const InputDecoration(
          labelText: 'Local folder nickname (optional)',
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: ready && !busy ? submit : null,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: Text(busy ? 'Creating folder…' : 'Generate and create folder'),
      ),
    ],
  );
}
