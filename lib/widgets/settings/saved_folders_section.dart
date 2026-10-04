import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../folders/saved_folder_tile.dart';
import '../folders/join_create_folder_popup.dart';

class SavedFoldersSection extends StatelessWidget {
  final DriveUiController controller;
  const SavedFoldersSection({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved folders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            'Removing a saved folder disconnects it from this device. Its files remain on the server.',
          ),
          const SizedBox(height: 12),
          for (final folder in controller.saved.folders)
            SavedFolderTile(folder: folder, controller: controller),
          if (controller.saved.folders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No saved folders for this server.'),
            ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () =>
                    JoinCreateFolderPopup.show(context, controller),
                icon: const Icon(Icons.login),
                label: const Text('Join folder'),
              ),
              TextButton.icon(
                onPressed: () => JoinCreateFolderPopup.show(
                  context,
                  controller,
                  create: true,
                ),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Create folder'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
