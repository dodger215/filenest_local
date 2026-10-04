import '../feedback/app_progress.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/drive_file.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/date_formatter.dart';
import '../../utils/file_size_formatter.dart';

class FilePreviewPopup extends StatefulWidget {
  final DriveUiController controller;
  final DriveFileModel file;
  final String folderId;
  const FilePreviewPopup({
    super.key,
    required this.controller,
    required this.file,
    required this.folderId,
  });
  @override
  State<FilePreviewPopup> createState() => _FilePreviewPopupState();
}

class _FilePreviewPopupState extends State<FilePreviewPopup> {
  Future<Uint8List>? image;
  @override
  void initState() {
    super.initState();
    if (widget.file.mimeType.startsWith('image/'))
      image = widget.controller.downloads.previewImage(
        folderId: widget.folderId,
        code: widget.file.folderCode,
        fileId: widget.file.id,
      );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.file;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                f.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Close preview',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (image != null)
          FutureBuilder<Uint8List>(
            future: image,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Text(DriveUiController.friendlyError(snapshot.error!));
              if (!snapshot.hasData)
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: AppProgress(circular: true, label: 'Fetching image'),
                  ),
                );
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  semanticLabel: f.name,
                  errorBuilder: (_, _, _) => const Text(
                    'This image format cannot be displayed. Download it to open it on your device.',
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        if (f.caption?.isNotEmpty == true) SelectableText(f.caption!),
        const SizedBox(height: 8),
        Text(formatFileSize(f.size)),
        Text(
          formatTimestamp(
            f.createdAt,
            use24Hour: widget.controller.settings.preferences.use24Hour,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => widget.controller.perform(() async {
            final uri = Uri.parse(
              f.webViewLink ??
                  widget.controller.connection
                      .uri('/files/${f.id}/content')
                      .toString(),
            );
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
              throw StateError('Unable to open the file URL.');
          }),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open file'),
        ),
      ],
    );
  }
}
