import 'package:flutter/material.dart';
import 'folder_nickname_dialog.dart';
import '../../data/models/saved_folder.dart';
import '../../state/drive_ui_controller.dart';
import '../../services/clipboard_service.dart';
import '../../services/code_share_service.dart';

class SavedFolderTile extends StatelessWidget {
  final SavedFolder folder;
  final DriveUiController controller;
  final VoidCallback? onOpen;
  const SavedFolderTile({
    super.key,
    required this.folder,
    required this.controller,
    this.onOpen,
  });
  Future<void> rename(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => FolderNicknameDialog(nickname: folder.nickname),
    );
    if (name != null)
      await controller.perform(
        () => controller.updateFolder(folder.copyWith(nickname: name)),
      );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.folder_outlined),
            title: Text(folder.label),
            subtitle: Text(
              folder.persisted ? 'Saved on this device' : 'This session only',
            ),
            trailing: controller.state.activeFolder?.folderId == folder.folderId
                ? const Icon(Icons.check_circle, color: Color(0xFF2563EB))
                : null,
            onTap:
                onOpen ??
                () => controller.perform(() => controller.openFolder(folder)),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed:
                    onOpen ??
                    () =>
                        controller.perform(() => controller.openFolder(folder)),
                child: const Text('Open'),
              ),
              IconButton(
                tooltip: folder.pinned ? 'Unpin folder' : 'Pin folder',
                onPressed: () => controller.perform(
                  () => controller.updateFolder(
                    folder.copyWith(pinned: !folder.pinned),
                  ),
                ),
                icon: Icon(
                  folder.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Copy code',
                onPressed: () => controller.perform(() async {
                  await ClipboardService.copy(folder.code);
                  controller.notice('Code copied.');
                }),
                icon: const Icon(Icons.copy_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'Saved folder actions',
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      rename(context);
                    case 'startup':
                      controller.perform(() async {
                        await controller.settings.set(
                          'last_folder:${controller.accountId}',
                          folder.folderId,
                        );
                        await controller.settings.set('reopen_last', 'true');
                        controller.notice('Startup folder set.');
                      });
                    case 'share':
                      controller.perform(
                        () => CodeShareService.share(
                          context,
                          folder.code,
                          backendUrl: controller.connection.baseUrl,
                        ),
                      );
                    case 'remove':
                      controller.perform(() => controller.removeFolder(folder));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Edit nickname')),
                  PopupMenuItem(
                    value: 'startup',
                    child: Text('Set as startup folder'),
                  ),
                  PopupMenuItem(value: 'share', child: Text('Share code')),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from this device'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
