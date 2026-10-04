import 'package:flutter/material.dart';
import '../../data/models/saved_folder.dart';
import '../../state/drive_ui_controller.dart';
import 'saved_folder_tile.dart';

class FolderCard extends StatelessWidget {
  final SavedFolder folder;
  final DriveUiController controller;
  const FolderCard({super.key, required this.folder, required this.controller});
  @override
  Widget build(BuildContext context) =>
      SavedFolderTile(folder: folder, controller: controller);
}
