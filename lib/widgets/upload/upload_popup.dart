import 'package:flutter/material.dart';
import '../../models/drive_directory.dart';
import '../../platform/file_picker_adapter.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/file_size_formatter.dart';
import 'upload_drop_zone.dart';
import 'selected_upload_file.dart';

class UploadPopup extends StatefulWidget {
  final DriveUiController controller;
  final DriveDirectory folder;
  const UploadPopup({
    super.key,
    required this.controller,
    required this.folder,
  });
  @override
  State<UploadPopup> createState() => _UploadPopupState();
}

class _UploadPopupState extends State<UploadPopup> {
  final selected = <PickedUpload>[];
  String? error;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Share files', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Upload files to folder ${widget.folder.code}.'),
      const SizedBox(height: 20),
      UploadDropZone(
        onFiles: (files) => setState(() {
          final total = [
            ...selected,
            ...files,
          ].fold<int>(0, (n, f) => n + f.bytes.length);
          if (total > FilePickerAdapter.maxBatchBytes) {
            error = 'Choose up to 250 MB per batch.';
          } else {
            selected.addAll(files);
            error = null;
          }
        }),
        onError: (e) => setState(() => error = e),
      ),
      const SizedBox(height: 16),
      for (final file in selected)
        SelectedUploadFile(
          key: ObjectKey(file),
          file: file,
          remove: () => setState(() => selected.remove(file)),
        ),
      if (selected.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${selected.length} selected · ${formatFileSize(selected.fold<int>(0, (n, f) => n + f.bytes.length))}',
          ),
        ),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      FilledButton.icon(
        onPressed: selected.isEmpty
            ? null
            : () {
                try {
                  widget.controller.enqueueUploads(selected, widget.folder);
                  Navigator.pop(context);
                } catch (e) {
                  setState(() => error = DriveUiController.friendlyError(e));
                }
              },
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload and share'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}
