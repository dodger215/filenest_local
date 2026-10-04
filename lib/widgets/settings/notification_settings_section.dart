import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../../state/drive_ui_controller.dart';

class NotificationSettingsSection extends StatelessWidget {
  final DriveUiController controller;
  const NotificationSettingsSection({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable notifications'),
            value: controller.settings.preferences.notifications,
            onChanged: (v) => controller.perform(
              () => controller.setPreference('notifications', '$v'),
            ),
          ),
          for (final folder in controller.saved.folders)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(folder.label),
              value: folder.notificationsEnabled,
              onChanged: (v) => controller.perform(
                () => controller.updateFolder(
                  folder.copyWith(notificationsEnabled: v),
                ),
              ),
            ),
          Text('Device permission: ${controller.devicePermission}'),
          TextButton(
            onPressed: () =>
                controller.perform(controller.enableDeviceNotifications),
            child: const Text('Request device notification permission'),
          ),
          if (controller.supportsDeviceNotifications)
            TextButton(
              onPressed: () => controller.perform(
                () => AppSettings.openAppSettings(
                  type: AppSettingsType.notification,
                ),
              ),
              child: const Text('Open device notification settings'),
            ),
          TextButton(
            onPressed: () =>
                controller.perform(controller.refreshDevicePermission),
            child: const Text('Refresh permission status'),
          ),
          const Text(
            'Notifications check the active folder while FileNest is running. They are not reliable push delivery when the app is closed.',
          ),
        ],
      ),
    ),
  );
}
