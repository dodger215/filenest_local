import 'package:flutter/material.dart';
import '../feedback/app_progress.dart';
import '../../state/transfer_job.dart';
import '../../state/drive_ui_controller.dart';

class TransferJobTile extends StatelessWidget {
  final TransferJob job;
  final DriveUiController controller;
  const TransferJobTile({
    super.key,
    required this.job,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              job.upload
                  ? Icons.cloud_upload_outlined
                  : Icons.download_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('${job.name} · ${job.code}')),
            const SizedBox(width: 8),
            Text(job.status.name),
            if (job.status == TransferStatus.failed ||
                job.status == TransferStatus.stopped)
              IconButton(
                tooltip: 'Retry ${job.name}',
                onPressed: () => controller.retry(job),
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
        if (job.status == TransferStatus.running) ...[
          const SizedBox(height: 8),
          AppProgress(
            value: job.progress,
            label: '${job.upload ? 'Uploading' : 'Downloading'} ${job.name}',
          ),
          if (job.progress != null)
            Text(
              '${(job.progress! * 100).toStringAsFixed(0)}% transferred${job.progress == 1 && job.upload ? ' · Waiting for server confirmation' : ''}',
            ),
        ],
        if (job.error != null)
          Text(
            job.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (job.localPath != null)
          SelectableText(
            job.localPath!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
  );
}
