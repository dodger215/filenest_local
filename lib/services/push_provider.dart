import '../models/drive_notification.dart';

/// Extension point for a future server-backed push implementation.
abstract interface class PushProvider {
  Stream<DriveNotification> get notifications;
  Future<void> subscribe(String accountId, String folderId);
  Future<void> dispose();
}
