import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';

class AppearanceSettingsSection extends StatelessWidget {
  final DriveUiController controller;
  const AppearanceSettingsSection({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final prefs = controller.settings.preferences;
    void set(String key, String value) =>
        controller.perform(() => controller.setPreference(key, value));
    Widget select(
      String label,
      String key,
      String value,
      Map<String, String> choices,
    ) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$key$value'),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final entry in choices.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (v) => set(key, v!),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance and display',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            select('Theme', 'theme', prefs.theme.name, {
              'system': 'System',
              'light': 'Light',
              'dark': 'Dark',
            }),
            select('Default file view', 'view', prefs.grid ? 'grid' : 'list', {
              'list': 'List',
              'grid': 'Grid',
            }),
            select('Time format', 'time', prefs.use24Hour ? '24' : '12', {
              '12': '12-hour',
              '24': '24-hour',
            }),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show relative date labels'),
              value: prefs.relativeDates,
              onChanged: (v) => set('relative_dates', '$v'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reopen last folder on launch'),
              value: prefs.reopenLast,
              onChanged: (v) => set('reopen_last', '$v'),
            ),
          ],
        ),
      ),
    );
  }
}
