class DriveDirectory {
  final String code;
  final String folderId;
  final DateTime? createdAt;
  final bool ownedByMe;
  final String? webViewLink;

  const DriveDirectory({
    required this.code,
    required this.folderId,
    this.createdAt,
    this.ownedByMe = false,
    this.webViewLink,
  });
}
