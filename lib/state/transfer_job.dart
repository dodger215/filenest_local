import 'dart:typed_data';
import '../models/drive_file.dart';

enum TransferStatus { queued, running, complete, failed, stopped }

class TransferJob {
  final String accountId, folderId, code, name;
  final bool upload;
  Uint8List? bytes;
  final String? caption;
  final DriveFileModel? file;
  String? uploadId, error, localPath;
  int transferred = 0;
  int? total;
  TransferStatus status = TransferStatus.queued;
  TransferJob.upload({
    required this.accountId,
    required this.folderId,
    required this.code,
    required this.name,
    required this.bytes,
    this.caption,
  }) : upload = true,
       file = null,
       total = bytes?.length;
  TransferJob.download({
    required this.accountId,
    required this.folderId,
    required this.code,
    required DriveFileModel source,
  }) : upload = false,
       file = source,
       name = source.name,
       caption = null,
       total = source.size;
  double? get progress => total == null || total == 0
      ? null
      : (transferred / total!).clamp(0.0, 1.0).toDouble();
}
