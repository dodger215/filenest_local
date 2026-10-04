import 'drive_file.dart';

class DriveNotification {
  final String directoryCode;
  final String? folderId;
  final DriveFileModel file;
  final DateTime detectedAt;

  const DriveNotification({
    required this.directoryCode,
    this.folderId,
    required this.file,
    required this.detectedAt,
  });
}
