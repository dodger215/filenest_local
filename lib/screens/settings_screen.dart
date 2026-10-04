import 'package:flutter/material.dart';
import '../state/drive_ui_controller.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/settings/backend_settings_section.dart';
import '../widgets/settings/saved_folders_section.dart';
import '../widgets/settings/notification_settings_section.dart';
import '../widgets/settings/appearance_settings_section.dart';

class SettingsScreen extends StatelessWidget {
  final DriveUiController controller;
  final bool dialog;
  const SettingsScreen({
    super.key,
    required this.controller,
    this.dialog = false,
  });
  static Future<void> show(
    BuildContext context,
    DriveUiController controller,
  ) async {
    if (ResponsiveLayout.isMobile(context)) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(controller: controller),
        ),
      );
    } else {
      await showAdaptivePopup<void>(
        context,
        SettingsScreen(controller: controller, dialog: true),
        width: 760,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dialog)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close settings',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          BackendSettingsSection(controller: controller),
          const SizedBox(height: 12),
          SavedFoldersSection(controller: controller),
          const SizedBox(height: 12),
          NotificationSettingsSection(controller: controller),
          const SizedBox(height: 12),
          AppearanceSettingsSection(controller: controller),
          const SizedBox(height: 12),
        ],
      );
      return dialog
          ? content
          : Scaffold(
              appBar: AppBar(title: const Text('Settings')),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ),
            );
    },
  );
}
