import '../feedback/app_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../models/drive_directory.dart';
import '../../state/drive_ui_controller.dart';
import '../../state/text_editor_controller.dart';
import '../../state/transfer_job.dart';
import '../feedback/unsaved_changes_dialog.dart';
import 'text_editor_toolbar.dart';
import 'text_filename_field.dart';

class CreateTextPopup extends StatefulWidget {
  final DriveUiController controller;
  final DriveDirectory folder;
  final String destination;
  const CreateTextPopup({
    super.key,
    required this.controller,
    required this.folder,
    required this.destination,
  });
  @override
  State<CreateTextPopup> createState() => _CreateTextPopupState();
}

class _CreateTextPopupState extends State<CreateTextPopup> {
  final draft = TextEditorController();
  TransferJob? job;
  bool closing = false;
  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  bool get submitted =>
      job != null &&
      job!.status != TransferStatus.failed &&
      job!.status != TransferStatus.stopped;
  Future<void> close() async {
    if (closing) return;
    closing = true;
    final discard =
        submitted || !draft.dirty || await confirmDiscardDraft(context);
    closing = false;
    if (discard && mounted) {
      setState(() => allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  bool allowPop = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([draft, widget.controller]),
    builder: (context, _) {
      final running =
          job?.status == TransferStatus.running ||
          job?.status == TransferStatus.queued;
      final done = job?.status == TransferStatus.complete;
      return PopScope(
        canPop: allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create text file',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close editor',
                  onPressed: close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text('Destination: ${widget.destination}'),
            const SizedBox(height: 20),
            TextFilenameField(controller: draft.filename, enabled: job == null),
            const SizedBox(height: 16),
            TextField(
              controller: draft.caption,
              enabled: job == null,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
              ),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: job != null,
              child: TextEditorToolbar(controller: draft.editor),
            ),
            Container(
              height: MediaQuery.viewInsetsOf(context).bottom > 0 ? 200 : 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AbsorbPointer(
                absorbing: job != null,
                child: QuillEditor.basic(
                  controller: draft.editor,
                  config: const QuillEditorConfig(
                    padding: EdgeInsets.all(16),
                    placeholder: 'Start writing…',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('${draft.words} words · ${draft.characters} characters'),
            const SizedBox(height: 16),
            const Text(
              'TXT saves the text and line breaks. Rich formatting will not be included.',
            ),
            const SizedBox(height: 12),
            if (job?.error != null)
              Text(
                job!.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (running)
              AppProgress(value: job!.progress, label: 'Uploading text file'),
            if (done)
              const Text(
                'Upload complete — your file is available in this folder.',
              ),
            if (!done)
              FilledButton.icon(
                onPressed: running || (job == null && draft.validation != null)
                    ? null
                    : () {
                        if (job != null) {
                          widget.controller.retry(job!);
                        } else {
                          widget.controller.enqueueUploads([
                            draft.export(),
                          ], widget.folder);
                          setState(
                            () => job = widget.controller.state.transfers.last,
                          );
                        }
                      },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  running
                      ? 'Uploading…'
                      : job != null
                      ? 'Retry upload'
                      : 'Upload text file',
                ),
              ),
            if (job == null && draft.validation != null)
              Text(
                draft.validation!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            TextButton(
              onPressed: close,
              child: Text(
                running
                    ? 'Continue in background'
                    : done
                    ? 'Done'
                    : 'Cancel',
              ),
            ),
          ],
        ),
      );
    },
  );
}
