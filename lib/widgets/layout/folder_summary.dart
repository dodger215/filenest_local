import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/date_formatter.dart';
import '../../utils/file_size_formatter.dart';

class FolderSummary extends StatelessWidget {
  final DriveUiController controller;
  const FolderSummary({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final folder = s.activeFolder;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.activeSaved?.nickname.isNotEmpty == true
                        ? controller.activeSaved!.nickname
                        : 'Your shared space',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh folder',
                  onPressed: s.loading ? null : controller.refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                Text('Folder · ${folder?.code ?? '—'}'),
                Text('${s.files.length} loaded files'),
                Text(
                  '${formatFileSize(s.files.fold<int>(0, (n, f) => n + (f.size ?? 0)))} known size',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.refreshedAt == null
                  ? 'Not refreshed yet'
                  : 'Refreshed ${formatTimestamp(s.refreshedAt, use24Hour: controller.settings.preferences.use24Hour)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
