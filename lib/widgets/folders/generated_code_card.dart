import 'package:flutter/material.dart';
import '../../data/models/saved_folder.dart';
import '../../services/code_share_service.dart';
import '../../state/drive_ui_controller.dart';
import '../feedback/animated_success_icon.dart';
import 'copy_code_button.dart';

class GeneratedCodeCard extends StatelessWidget {
  final SavedFolder folder;
  final bool saved, busy;
  final VoidCallback retrySaving, useFolder;
  final DriveUiController controller;
  const GeneratedCodeCard({
    super.key,
    required this.folder,
    required this.saved,
    required this.busy,
    required this.retrySaving,
    required this.useFolder,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: AnimatedSuccessIcon()),
      const SizedBox(height: 16),
      Text(
        'Your folder is ready',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      SelectableText(
        folder.code,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          letterSpacing: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          CopyCodeButton(code: folder.code),
          TextButton.icon(
            onPressed: () => controller.perform(
              () => CodeShareService.share(
                context,
                folder.code,
                backendUrl: controller.connection.baseUrl,
              ),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share code'),
          ),
        ],
      ),
      const Text(
        'Share this code with people connected to the same backend server. No account is required.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      if (!saved)
        OutlinedButton.icon(
          onPressed: busy ? null : retrySaving,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Retry saving'),
        ),
      FilledButton.icon(
        onPressed: busy || !saved ? null : useFolder,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Use this folder'),
      ),
    ],
  );
}
