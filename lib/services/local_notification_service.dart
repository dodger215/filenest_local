import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/drive_notification.dart';

class LocalNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  int _nextId = 0;
  bool _initialized = false;
  Future<void> initialize({
    void Function(String? payload)? onTap,
    bool requestPermission = true,
  }) async {
    if (!_initialized) {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onTap?.call(response.payload),
      );
      _initialized = true;
    }
    if (requestPermission) await _requestPermission();
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<String> permissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled == true ? 'Granted' : 'Denied or not requested';
    }
    final options = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return options?.isEnabled == true ? 'Granted' : 'Denied or not requested';
  }

  Future<String> initializeAndRequest() async {
    await initialize();
    return permissionStatus();
  }

  Future<void> show(DriveNotification event) => _plugin.show(
    _nextId++,
    'New file in ${event.directoryCode}',
    event.file.name,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'drive_files',
        'Shared files',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: '${event.directoryCode}/${event.file.id}',
  );
}
