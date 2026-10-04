class FileUploadRequest {
  final String directoryCode;
  final String filePath;
  final String? caption;

  const FileUploadRequest({
    required this.directoryCode,
    required this.filePath,
    this.caption,
  });
}
