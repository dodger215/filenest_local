import '../feedback/app_progress.dart';
import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../../state/transfer_job.dart';
import '../layout/responsive_layout.dart';
import 'transfer_job_tile.dart';

class TransferProgressBar extends StatefulWidget {
  final DriveUiController controller;
  const TransferProgressBar({super.key, required this.controller});
  @override
  State<TransferProgressBar> createState() => _TransferProgressBarState();
}

class _TransferProgressBarState extends State<TransferProgressBar> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final jobs = widget.controller.state.transfers;
    if (jobs.isEmpty) return const SizedBox.shrink();
    final running = jobs
        .where((j) => j.status == TransferStatus.running)
        .firstOrNull;
    final complete = jobs
        .where((j) => j.status == TransferStatus.complete)
        .length;
    final failed = jobs.where((j) => j.status == TransferStatus.failed).length;
    final stopped = jobs
        .where((j) => j.status == TransferStatus.stopped)
        .length;
    final label = running == null
        ? '$complete completed · $failed failed${stopped > 0 ? ' · $stopped stopped' : ''}'
        : '${running.upload ? 'Uploading' : 'Downloading'} ${jobs.indexOf(running) + 1} of ${jobs.length}';
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (running != null)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: AppProgress(
                        circular: true,
                        label: 'Transfer active',
                      ),
                    )
                  else
                    Icon(
                      failed > 0
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label),
                        if (running != null)
                          Text(
                            running.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: expanded
                        ? 'Collapse transfers'
                        : 'Expand transfers',
                    onPressed: () => setState(() => expanded = !expanded),
                    icon: Icon(
                      expanded ? Icons.expand_more : Icons.expand_less,
                    ),
                  ),
                ],
              ),
              if (running != null)
                AppProgress(value: running.progress, label: label),
              AnimatedSize(
                duration: ResponsiveLayout.duration(context),
                child: expanded
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .3,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final job in jobs)
                                TransferJobTile(
                                  job: job,
                                  controller: widget.controller,
                                ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (jobs.any(
                                    (j) => j.status == TransferStatus.queued,
                                  ))
                                    TextButton(
                                      onPressed:
                                          widget.controller.stopRemaining,
                                      child: const Text(
                                        'Stop remaining transfers',
                                      ),
                                    ),
                                  if (complete > 0)
                                    TextButton(
                                      onPressed:
                                          widget.controller.dismissCompleted,
                                      child: const Text('Dismiss completed'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
