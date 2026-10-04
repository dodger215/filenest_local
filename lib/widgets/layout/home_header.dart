import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../../screens/settings_screen.dart';
import '../branding/filenest_logo.dart';
import '../folders/folder_switcher.dart';
import '../folders/saved_folder_switcher.dart';
import '../folders/copy_code_button.dart';
import '../folders/invite_people_popup.dart';
import '../feedback/notification_panel.dart';
import '../upload/upload_method_selector.dart';
import 'responsive_layout.dart';

class HomeHeader extends StatelessWidget {
  final DriveUiController controller;
  const HomeHeader({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final folder = c.state.activeFolder;
    void settings() => SettingsScreen.show(context, c);
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: folder == null
              ? null
              : () => UploadMethodSelector.show(context, c),
          icon: const Icon(Icons.add),
          label: const Text('Share files'),
        ),
        OutlinedButton.icon(
          onPressed: c.state.selected.isEmpty
              ? null
              : () => c.downloadFiles(
                  c.state.files.where((f) => c.state.selected.contains(f.id)),
                ),
          icon: const Icon(Icons.download_outlined),
          label: Text(
            c.state.selected.isEmpty
                ? 'Download'
                : 'Download (${c.state.selected.length})',
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FileNestLogo(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FileNest',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 1150) ...[
                actions,
                const SizedBox(width: 16),
              ],
              IconButton(
                tooltip:
                    'Notifications${c.state.unread > 0 ? ', ${c.state.unread} unread' : ''}',
                onPressed: () {
                  c.markRead();
                  showAdaptivePopup<void>(
                    context,
                    NotificationPanel(controller: c),
                  );
                },
                icon: Badge(
                  isLabelVisible: c.state.unread > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
              if (MediaQuery.sizeOf(context).width >= 500)
                IconButton(
                  tooltip: 'Settings',
                  onPressed: settings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              PopupMenuButton<String>(
                tooltip: 'Folder actions',
                onSelected: (value) {
                  switch (value) {
                    case 'invite':
                      if (folder != null)
                        showAdaptivePopup<void>(
                          context,
                          InvitePeoplePopup(controller: c, folder: folder),
                        );
                    case 'switch':
                      showAdaptivePopup<void>(
                        context,
                        SavedFolderSwitcher(controller: c, manage: settings),
                      );
                    case 'settings':
                      settings();
                  }
                },
                itemBuilder: (_) => [
                  if (folder?.ownedByMe == true)
                    const PopupMenuItem(
                      value: 'invite',
                      child: Text('Invite people'),
                    ),
                  const PopupMenuItem(
                    value: 'switch',
                    child: Text('Switch folder'),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 18,
                    child: const Icon(Icons.dns_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 48,
                ),
                child: FolderSwitcher(controller: c, manage: settings),
              ),
              if (folder != null) CopyCodeButton(code: folder.code),
            ],
          ),
          if (MediaQuery.sizeOf(context).width < 1150) ...[
            const SizedBox(height: 16),
            actions,
          ],
        ],
      ),
    );
  }
}
