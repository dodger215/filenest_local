import 'package:flutter/material.dart';
import '../../models/file_filter.dart';
import '../../state/drive_ui_controller.dart';
import '../../state/drive_ui_state.dart';
import '../../utils/date_formatter.dart';

class FileFilterPopup extends StatefulWidget {
  final DriveUiController controller;
  const FileFilterPopup({super.key, required this.controller});
  @override
  State<FileFilterPopup> createState() => _FileFilterPopupState();
}

class _FileFilterPopupState extends State<FileFilterPopup> {
  late Set<String> extensions = {...widget.controller.state.filter.extensions};
  late DateTime? from = widget.controller.state.filter.from,
      to = widget.controller.state.filter.to;
  late FileSort sort = widget.controller.state.sort;
  Future<void> date(bool start) async {
    final initial = (start ? from : to) ?? DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (start) {
        from = value;
      } else {
        to = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final invalid = from != null && to != null && from!.isAfter(to!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Filter files', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        const Text('Extensions'),
        Wrap(
          spacing: 8,
          children: [
            for (final ext in [
              'pdf',
              'docx',
              'xlsx',
              'jpg',
              'png',
              'mp4',
              'mp3',
              'zip',
            ])
              FilterChip(
                label: Text(ext.toUpperCase()),
                selected: extensions.contains(ext),
                onSelected: (v) => setState(() {
                  v ? extensions.add(ext) : extensions.remove(ext);
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => date(true),
          icon: const Icon(Icons.event),
          label: Text(
            from == null ? 'Start date and time' : formatTimestamp(from),
          ),
        ),
        if (from != null)
          TextButton(
            onPressed: () => setState(() => from = null),
            child: const Text('Clear start'),
          ),
        OutlinedButton.icon(
          onPressed: () => date(false),
          icon: const Icon(Icons.event),
          label: Text(to == null ? 'End date and time' : formatTimestamp(to)),
        ),
        if (to != null)
          TextButton(
            onPressed: () => setState(() => to = null),
            child: const Text('Clear end'),
          ),
        if (invalid)
          Text(
            'End must be at or after start.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<FileSort>(
          initialValue: sort,
          decoration: const InputDecoration(labelText: 'Sort by'),
          items: [
            for (final value in FileSort.values)
              DropdownMenuItem(value: value, child: Text(value.name)),
          ],
          onChanged: (v) => setState(() => sort = v!),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: invalid
              ? null
              : () {
                  widget.controller.setFilter(
                    FileFilter(from: from, to: to, extensions: extensions),
                  );
                  widget.controller.setSort(sort);
                  Navigator.pop(context);
                },
          child: const Text('Apply filters'),
        ),
        TextButton(
          onPressed: () {
            widget.controller.clearFilters();
            Navigator.pop(context);
          },
          child: const Text('Clear filters'),
        ),
      ],
    );
  }
}
