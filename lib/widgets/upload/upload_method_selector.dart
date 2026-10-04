import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../layout/responsive_layout.dart';
import 'upload_popup.dart';
import 'create_text_popup.dart';

class UploadMethodSelector extends StatelessWidget {
  final DriveUiController controller;
  const UploadMethodSelector({super.key, required this.controller});
  static Future<void> show(
    BuildContext context,
    DriveUiController controller,
  ) async {
    final folder = controller.state.activeFolder;
    if (folder == null) return;
    final destination = controller.activeSaved?.label ?? folder.code;
    final text = await showAdaptivePopup<bool>(
      context,
      UploadMethodSelector(controller: controller),
    );
    if (text == null || !context.mounted) return;
    if (text) {
      await showAdaptivePopup<void>(
        context,
        CreateTextPopup(
          controller: controller,
          folder: folder,
          destination: destination,
        ),
        width: 820,
        dismissible: false,
      );
    } else {
      await showAdaptivePopup<void>(
        context,
        UploadPopup(controller: controller, folder: folder),
        width: 640,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Share files', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      ListTile(
        minVerticalPadding: 20,
        leading: const Icon(Icons.cloud_upload_outlined),
        title: const Text('Upload files'),
        subtitle: const Text('Choose documents, images, and more.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pop(context, false),
      ),
      const Divider(),
      ListTile(
        minVerticalPadding: 20,
        leading: const Icon(Icons.edit_document),
        title: const Text('Create text file'),
        subtitle: const Text('Write a note and share it as TXT.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pop(context, true),
      ),
    ],
  );
}
