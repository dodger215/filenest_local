import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/drive_notification.dart';
import 'drive_file_service.dart';

/// Foreground polling. Events mean a file became visible since the baseline;
/// files moved into the folder are included. Existing baseline files are silent.
class DriveNotificationService with WidgetsBindingObserver {
  final DriveFileService files;
  final Duration interval;
  final _events = StreamController<DriveNotification>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  final Map<String, Set<String>> _seen = {};
  final Map<String, String?> _folderIds = {};
  Timer? _timer;
  bool _busy = false;
  bool _foreground = true;
  bool _disposed = false;
  int _generation = 0;

  DriveNotificationService(
    this.files, {
    this.interval = const Duration(seconds: 3),
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<DriveNotification> get notifications => _events.stream;
  Stream<Object> get errors => _errors.stream;

  Future<void> watch(String directoryCode, {String? folderId}) async {
    final generation = _generation;
    final code = directoryCode.trim().toUpperCase();
    final existing = await files.getFiles(
      directoryCode: code,
      folderId: folderId ?? _folderIds[code],
    );
    if (_disposed || generation != _generation) return;
    _folderIds[code] = folderId;
    _seen[code] = existing.map((f) => f.id).toSet();
    _timer ??= Timer.periodic(interval, (_) => unawaited(checkNow()));
  }

  void unwatch(String code) => _seen.remove(code.trim().toUpperCase());

  Future<void> checkNow() async {
    if (_busy || !_foreground || _disposed) return;
    _busy = true;
    final generation = _generation;
    try {
      for (final code in _seen.keys.toList()) {
        try {
          final current = await files.getFiles(
            directoryCode: code,
            folderId: _folderIds[code],
          );
          if (_disposed || generation != _generation) return;
          final seen = _seen[code];
          if (seen == null) continue;
          for (final file in current.reversed) {
            if (seen.add(file.id)) {
              _events.add(
                DriveNotification(
                  directoryCode: code,
                  folderId: _folderIds[code],
                  file: file,
                  detectedAt: DateTime.now(),
                ),
              );
            }
          }
        } catch (error) {
          if (!_disposed && generation == _generation) _errors.add(error);
        }
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(checkNow());
  }

  /// Call before changing servers. Re-watch after connecting to a folder.
  void stop() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _seen.clear();
    _folderIds.clear();
  }

  Future<void> dispose() async {
    stop();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _events.close();
    await _errors.close();
  }
}
