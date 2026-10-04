import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../../platform/file_picker_adapter.dart';
import '../../utils/file_size_formatter.dart';

class SelectedUploadFile extends StatelessWidget {
  final PickedUpload file;
  final VoidCallback remove;
  const SelectedUploadFile({
    super.key,
    required this.file,
    required this.remove,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              if ((lookupMimeType(file.name) ?? '').startsWith('image/'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    file.bytes,
                    width: 48,
                    height: 48,
                    cacheWidth: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name),
                    Text(
                      '${path.extension(file.name).toUpperCase()} · ${formatFileSize(file.bytes.length)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${file.name}',
                onPressed: remove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: file.caption,
            onChanged: (value) => file.caption = value,
            decoration: const InputDecoration(labelText: 'Caption (optional)'),
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}
