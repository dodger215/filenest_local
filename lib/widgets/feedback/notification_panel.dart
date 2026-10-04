import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/date_formatter.dart';

class NotificationPanel extends StatelessWidget {
  final DriveUiController controller;
  const NotificationPanel({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Notifications', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'FileNest checks for new files while the app is active. Closed-app push delivery is not available.',
        ),
        const SizedBox(height: 20),
        if (controller.state.notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('You’re all caught up.'),
          ),
        for (final event in controller.state.notifications)
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('New file in ${event.directoryCode}'),
            subtitle: Text(
              '${event.file.name} is now available.\n${formatTimestamp(event.detectedAt, use24Hour: controller.settings.preferences.use24Hour)}',
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
