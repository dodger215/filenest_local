import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import 'join_create_folder_popup.dart';

class JoinFolderPopup extends StatelessWidget {
  final DriveUiController controller;
  const JoinFolderPopup({super.key, required this.controller});
  @override
  Widget build(BuildContext context) =>
      JoinCreateFolderPopup(controller: controller);
}
