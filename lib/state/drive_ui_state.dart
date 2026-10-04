import '../models/drive_directory.dart';
import '../models/drive_file.dart';
import '../models/drive_notification.dart';
import '../models/file_filter.dart';
import '../utils/file_type_mapper.dart';
import 'transfer_job.dart';

enum FileSort { newest, oldest, name, size }

enum NoticeKind { success, information, warning, error }

class UiNotice {
  final String message;
  final NoticeKind kind;
  const UiNotice(this.message, [this.kind = NoticeKind.information]);
}

class DriveUiState {
  bool initializing = true, loading = false, connecting = false;
  String? initializationError, error;
  DriveDirectory? activeFolder;
  List<DriveFileModel> files = [];
  String search = '';
  FileKind kind = FileKind.all;
  FileFilter filter = const FileFilter();
  FileSort sort = FileSort.newest;
  final selected = <String>{};
  final highlighted = <String>{};
  final transfers = <TransferJob>[];
  final notifications = <DriveNotification>[];
  int unread = 0;
  DateTime? refreshedAt;
}
