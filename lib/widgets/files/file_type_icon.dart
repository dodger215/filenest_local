import 'package:flutter/material.dart';
import '../../models/drive_file.dart';
import '../../utils/file_type_mapper.dart';

class FileTypeIcon extends StatelessWidget {
  final DriveFileModel file;
  const FileTypeIcon({super.key, required this.file});
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (fileKind(file)) {
      FileKind.images => (Icons.image_outlined, Colors.purple),
      FileKind.videos => (Icons.videocam_outlined, Colors.red),
      FileKind.audio => (Icons.audiotrack_outlined, Colors.orange),
      FileKind.documents => (Icons.description_outlined, Colors.blue),
      _ => (Icons.insert_drive_file_outlined, Colors.blueGrey),
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}
