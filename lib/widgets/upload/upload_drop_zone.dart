import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../platform/file_picker_adapter.dart';

class UploadDropZone extends StatefulWidget {
  final ValueChanged<List<PickedUpload>> onFiles;
  final ValueChanged<String> onError;
  const UploadDropZone({
    super.key,
    required this.onFiles,
    required this.onError,
  });
  @override
  State<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<UploadDropZone> {
  final picker = FilePickerAdapter();
  bool hovering = false, busy = false;
  Future<void> receive(Future<List<PickedUpload>> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final files = await action();
      if (mounted) widget.onFiles(files);
    } catch (e) {
      if (mounted) widget.onError(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DropTarget(
    onDragEntered: (_) => setState(() => hovering = true),
    onDragExited: (_) => setState(() => hovering = false),
    onDragDone: (details) => receive(() => picker.fromDrop(details.files)),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: hovering ? .14 : .04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : () => receive(picker.pick),
            child: Text(busy ? 'Reading files…' : 'Choose files'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select files to share with this folder.',
            textAlign: TextAlign.center,
          ),
          const Text(
            'Or drop files here · Up to 100 MB per file',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
