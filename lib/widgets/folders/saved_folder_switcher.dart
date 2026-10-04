import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../layout/responsive_layout.dart';
import 'saved_folder_tile.dart';
import 'join_create_folder_popup.dart';

class SavedFolderSwitcher extends StatelessWidget {
  final DriveUiController controller;
  final VoidCallback manage;
  const SavedFolderSwitcher({
    super.key,
    required this.controller,
    required this.manage,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final folders = [...controller.saved.folders]
        ..sort(
          (a, b) => (b.lastOpenedAt ?? b.createdAt).compareTo(
            a.lastOpenedAt ?? a.createdAt,
          ),
        );
      final recent = folders
          .where((f) => !f.pinned && f.lastOpenedAt != null)
          .take(5)
          .toList();
      final groups = {
        'Pinned folders': folders.where((f) => f.pinned).toList(),
        'Recently opened': recent,
        'Other folders': folders
            .where((f) => !f.pinned && !recent.contains(f))
            .toList(),
      };
      return AnimatedSize(
        duration: ResponsiveLayout.duration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Available folders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('Folders saved or opened in FileNest.'),
            for (final group in groups.entries)
              if (group.value.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(
                    group.key,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final folder in group.value)
                  SavedFolderTile(
                    folder: folder,
                    controller: controller,
                    onOpen: () {
                      Navigator.pop(context);
                      controller.perform(() => controller.openFolder(folder));
                    },
                  ),
              ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                JoinCreateFolderPopup.show(context, controller);
              },
              icon: const Icon(Icons.login),
              label: const Text('Join another folder'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                JoinCreateFolderPopup.show(context, controller, create: true);
              },
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Create folder'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                manage();
              },
              child: const Text('Manage saved folders'),
            ),
          ],
        ),
      );
    },
  );
}
