import 'package:flutter/material.dart';
import '../../models/drive_directory.dart';
import '../../state/drive_ui_controller.dart';
import '../../services/code_share_service.dart';
import 'copy_code_button.dart';

class InvitePeoplePopup extends StatelessWidget {
  final DriveUiController controller;
  final DriveDirectory folder;
  const InvitePeoplePopup({
    super.key,
    required this.controller,
    required this.folder,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Share folder', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      const Text(
        'Set the same backend URL in Settings, then enter this folder code. Anyone connected to this server can upload and download files.',
      ),
      const SizedBox(height: 12),
      SelectableText(controller.connection.baseUrl),
      SelectableText(
        folder.code,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      CopyCodeButton(code: folder.code),
      FilledButton.icon(
        onPressed: () => controller.perform(
          () => CodeShareService.share(
            context,
            folder.code,
            backendUrl: controller.connection.baseUrl,
          ),
        ),
        icon: const Icon(Icons.share_outlined),
        label: const Text('Share connection details'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
