import 'package:path/path.dart' as path;

class DriveFileModel {
  final String id, folderCode, name, extension, mimeType;
  final String? caption, webViewLink, storagePath, category;
  final int? size;
  final DateTime? createdAt, modifiedAt;
  const DriveFileModel({
    required this.id,
    required this.folderCode,
    required this.name,
    required this.extension,
    required this.mimeType,
    this.caption,
    this.size,
    this.createdAt,
    this.modifiedAt,
    this.webViewLink,
    this.storagePath,
    this.category,
  });
  factory DriveFileModel.fromJson(
    Map<String, dynamic> file,
    String code,
    String downloadUrl,
  ) {
    final name = file['name'] as String;
    return DriveFileModel(
      id: file['id'] as String,
      folderCode: code,
      name: name,
      extension: path.extension(name).replaceFirst('.', '').toLowerCase(),
      mimeType: file['mimeType'] as String,
      caption: file['caption'] as String?,
      size: file['size'] as int?,
      createdAt: DateTime.tryParse(file['createdAt'] as String? ?? ''),
      modifiedAt: DateTime.tryParse(file['modifiedAt'] as String? ?? ''),
      webViewLink: downloadUrl,
      storagePath: file['path'] as String?,
      category: file['category'] as String?,
    );
  }
}
