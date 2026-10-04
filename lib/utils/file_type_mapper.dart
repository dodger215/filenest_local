import '../models/drive_file.dart';

enum FileKind { all, documents, images, videos, audio, other }

FileKind fileKind(DriveFileModel file) {
  for (final kind in FileKind.values) {
    if (kind != FileKind.all && kind.name == file.category) return kind;
  }
  if (file.mimeType.startsWith('image/')) return FileKind.images;
  if (file.mimeType.startsWith('video/')) return FileKind.videos;
  if (file.mimeType.startsWith('audio/')) return FileKind.audio;
  if (file.mimeType.startsWith('text/') ||
      [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'csv',
      ].contains(file.extension))
    return FileKind.documents;
  return FileKind.other;
}

String kindLabel(FileKind kind) => switch (kind) {
  FileKind.all => 'All',
  FileKind.documents => 'Documents',
  FileKind.images => 'Images',
  FileKind.videos => 'Videos',
  FileKind.audio => 'Audio',
  FileKind.other => 'Other',
};
