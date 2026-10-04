import '../../models/drive_directory.dart';

class SavedFolder {
  final String accountId, folderId, code, nickname;
  final String? ownerEmail, cachedRole;
  final bool pinned, notificationsEnabled, persisted;
  final DateTime createdAt;
  final DateTime? lastOpenedAt, lastValidatedAt;
  const SavedFolder({
    required this.accountId,
    required this.folderId,
    required this.code,
    required this.createdAt,
    this.nickname = '',
    this.ownerEmail,
    this.cachedRole,
    this.pinned = false,
    this.notificationsEnabled = true,
    this.persisted = true,
    this.lastOpenedAt,
    this.lastValidatedAt,
  });
  String get label => nickname.isEmpty ? code : '$nickname · $code';
  factory SavedFolder.fromDirectory(
    String accountId,
    DriveDirectory f, {
    String nickname = '',
    bool persisted = true,
  }) => SavedFolder(
    accountId: accountId,
    folderId: f.folderId,
    code: f.code,
    nickname: nickname,
    createdAt: DateTime.now(),
    lastValidatedAt: DateTime.now(),
    persisted: persisted,
    cachedRole: f.ownedByMe ? 'owner' : null,
  );
  factory SavedFolder.fromMap(Map<String, Object?> m) => SavedFolder(
    accountId: m['backend_url'] as String,
    folderId: m['folder_id'] as String,
    code: m['folder_code'] as String,
    nickname: m['local_nickname'] as String,
    ownerEmail: m['owner_email'] as String?,
    cachedRole: m['cached_role'] as String?,
    pinned: m['is_pinned'] == 1,
    notificationsEnabled: m['notifications_enabled'] == 1,
    createdAt: DateTime.parse(m['created_at'] as String),
    lastOpenedAt: DateTime.tryParse(m['last_opened_at'] as String? ?? ''),
    lastValidatedAt: DateTime.tryParse(m['last_validated_at'] as String? ?? ''),
  );
  Map<String, Object?> toMap() => {
    'backend_url': accountId,
    'folder_id': folderId,
    'folder_code': code,
    'local_nickname': nickname,
    'owner_email': ownerEmail,
    'cached_role': cachedRole,
    'is_pinned': pinned ? 1 : 0,
    'notifications_enabled': notificationsEnabled ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'last_opened_at': lastOpenedAt?.toUtc().toIso8601String(),
    'last_validated_at': lastValidatedAt?.toUtc().toIso8601String(),
  };
  SavedFolder copyWith({
    String? nickname,
    bool? pinned,
    bool? notificationsEnabled,
    DateTime? lastOpenedAt,
    DateTime? lastValidatedAt,
    String? code,
  }) => SavedFolder(
    accountId: accountId,
    folderId: folderId,
    code: code ?? this.code,
    nickname: nickname ?? this.nickname,
    ownerEmail: ownerEmail,
    cachedRole: cachedRole,
    pinned: pinned ?? this.pinned,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    persisted: persisted,
    createdAt: createdAt,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
  );
}
