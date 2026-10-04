import 'package:flutter/material.dart';
import '../../models/drive_file.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/date_formatter.dart';
import '../../utils/file_size_formatter.dart';
import '../layout/responsive_layout.dart';
import 'file_preview_popup.dart';
import 'file_type_icon.dart';

class FileTable extends StatelessWidget {
  final List<DriveFileModel> files;
  final DriveUiController controller;
  const FileTable({super.key, required this.files, required this.controller});
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text('FILE')),
              Expanded(flex: 3, child: Text('UPLOADED')),
              Expanded(child: Text('SIZE')),
              SizedBox(width: 152),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final file in files)
          Builder(
            builder: (context) {
              void preview() => showAdaptivePopup<void>(
                context,
                FilePreviewPopup(
                  controller: controller,
                  file: file,
                  folderId: controller.state.activeFolder!.folderId,
                ),
                width: 760,
              );
              return Material(
                color: controller.state.highlighted.contains(file.id)
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                child: InkWell(
                  onTap: preview,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Checkbox(
                                semanticLabel: 'Select ${file.name}',
                                value: controller.state.selected.contains(
                                  file.id,
                                ),
                                onChanged: (v) =>
                                    controller.select(file.id, v!),
                              ),
                              FileTypeIcon(file: file),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    if (file.caption?.isNotEmpty == true)
                                      Text(
                                        file.caption!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      file.extension.toUpperCase(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              formatTimestamp(
                                file.createdAt,
                                use24Hour:
                                    controller.settings.preferences.use24Hour,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        Expanded(child: Text(formatFileSize(file.size))),
                        IconButton(
                          tooltip: 'Preview ${file.name}',
                          onPressed: preview,
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          tooltip: 'Download ${file.name}',
                          onPressed: () => controller.downloadFiles([file]),
                          icon: const Icon(Icons.download_outlined),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'File actions',
                          onSelected: (v) => v == 'preview'
                              ? preview()
                              : controller.downloadFiles([file]),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'preview',
                              child: Text('Preview'),
                            ),
                            PopupMenuItem(
                              value: 'download',
                              child: Text('Download'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
