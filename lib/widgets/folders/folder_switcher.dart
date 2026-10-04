import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../layout/responsive_layout.dart';
import 'saved_folder_switcher.dart';

class FolderSwitcher extends StatelessWidget {
  final DriveUiController controller;
  final VoidCallback manage;
  const FolderSwitcher({
    super.key,
    required this.controller,
    required this.manage,
  });
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => showAdaptivePopup<void>(
      context,
      SavedFolderSwitcher(controller: controller, manage: manage),
    ),
    icon: const Icon(Icons.folder_outlined),
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            controller.activeSaved?.label ??
                controller.state.activeFolder?.code ??
                'Switch folder',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.expand_more),
      ],
    ),
  );
}
