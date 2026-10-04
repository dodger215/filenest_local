import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';

class SelectionToolbar extends StatelessWidget {
  final DriveUiController controller;
  const SelectionToolbar({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final files = controller.filteredFiles;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              semanticLabel: 'Select all filtered files',
              value:
                  files.isNotEmpty &&
                  files.every((f) => controller.state.selected.contains(f.id)),
              onChanged: files.isEmpty ? null : (v) => controller.selectAll(v!),
            ),
            const Text('Select all'),
          ],
        ),
        Text('${files.length} files found'),
        if (controller.state.selected.isNotEmpty)
          Text('${controller.state.selected.length} selected'),
      ],
    );
  }
}
