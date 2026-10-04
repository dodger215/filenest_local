import 'package:flutter/material.dart';
import '../../models/drive_file.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/date_formatter.dart';
import '../../utils/file_size_formatter.dart';
import '../layout/responsive_layout.dart';
import 'file_type_icon.dart';
import 'file_preview_popup.dart';

class FileCard extends StatelessWidget {
  final DriveFileModel file;
  final DriveUiController controller;
  const FileCard({super.key, required this.file, required this.controller});
  void preview(BuildContext context) => showAdaptivePopup<void>(
    context,
    FilePreviewPopup(
      controller: controller,
      file: file,
      folderId: controller.state.activeFolder!.folderId,
    ),
    width: 760,
  );
  @override
  Widget build(BuildContext context) => Card(
    color: controller.state.highlighted.contains(file.id)
        ? Theme.of(context).colorScheme.primaryContainer
        : null,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => preview(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FileTypeIcon(file: file),
                const Spacer(),
                Checkbox(
                  semanticLabel: 'Select ${file.name}',
                  value: controller.state.selected.contains(file.id),
                  onChanged: (v) => controller.select(file.id, v!),
                ),
                PopupMenuButton<String>(
                  tooltip: 'File actions',
                  onSelected: (v) {
                    if (v == 'preview') {
                      preview(context);
                    } else {
                      controller.downloadFiles([file]);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'preview', child: Text('Preview')),
                    PopupMenuItem(value: 'download', child: Text('Download')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(file.name, style: Theme.of(context).textTheme.titleMedium),
            if (file.caption?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  file.caption!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    file.extension.isEmpty
                        ? 'FILE'
                        : file.extension.toUpperCase(),
                  ),
                ),
                Text(formatFileSize(file.size)),
              ],
            ),
            Text(
              formatTimestamp(
                file.createdAt,
                use24Hour: controller.settings.preferences.use24Hour,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: () => preview(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'),
                ),
                TextButton.icon(
                  onPressed: () => controller.downloadFiles([file]),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
