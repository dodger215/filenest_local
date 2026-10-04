import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/saved_folder.dart';
import '../data/repositories/saved_folder_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../models/drive_directory.dart';
import '../models/drive_file.dart';
import '../models/file_filter.dart';
import '../platform/file_picker_adapter.dart';
import '../services/backend_connection.dart';
import '../config/backend_config.dart';
import '../services/drive_directory_service.dart';
import '../services/drive_file_service.dart';
import '../services/drive_upload_service.dart';
import '../services/drive_download_service.dart';
import '../services/drive_notification_service.dart';
import '../services/local_notification_service.dart';
import '../utils/file_type_mapper.dart';
import 'drive_ui_state.dart';
import 'saved_folders_controller.dart';
import 'settings_controller.dart';
import 'transfer_job.dart';

class DriveUiController extends ChangeNotifier {
  final BackendConnection connection;
  final AppDatabase database;
  late final DriveDirectoryService directories = DriveDirectoryService(
    connection,
  );
  late final DriveFileService files = DriveFileService(connection, directories);
  late final DriveUploadService uploads = DriveUploadService(
    connection,
    directories,
  );
  late final DriveDownloadService downloads = DriveDownloadService(
    connection,
    files,
  );
  late final DriveNotificationService watcher = DriveNotificationService(files);
  late final SavedFoldersController saved = SavedFoldersController(
    SavedFolderRepository(database),
  );
  late final SettingsController settings = SettingsController(
    SettingsRepository(database),
  );
  final LocalNotificationService localNotifications =
      LocalNotificationService();
  final DriveUiState state = DriveUiState();
  final _notices = StreamController<UiNotice>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false,
      _watchReady = false,
      _localReady = false,
      _queueRunning = false;
  int _generation = 0, _refresh = 0;
  SavedFolder? _lastAttemptedFolder;
  String devicePermission = 'Not requested';
  Stream<UiNotice> get notices => _notices.stream;
  DriveUiController({
    BackendConnection? connection,
    AppDatabase? database,
    String? backendUrl,
  }) : connection = connection ?? BackendConnection(baseUrl: backendUrl),
       database = database ?? AppDatabase() {
    saved.addListener(changed);
    settings.addListener(changed);
  }
  // Local records are scoped to the server, without user accounts.
  String get accountId => connection.baseUrl;
  bool get transfersRunning =>
      state.transfers.any((j) => j.status == TransferStatus.running);
  SavedFolder? get activeSaved {
    for (final f in saved.folders) {
      if (f.folderId == state.activeFolder?.folderId) return f;
    }
    return null;
  }

  void changed() {
    if (!_disposed) notifyListeners();
  }

  void notice(String message, [NoticeKind kind = NoticeKind.information]) {
    if (!_disposed) _notices.add(UiNotice(message, kind));
  }

  static String friendlyError(Object e) {
    final message = e.toString();
    if (RegExp(
      'SocketException|ClientException|Failed to fetch|network',
      caseSensitive: false,
    ).hasMatch(message))
      return 'Connection lost. Check the backend URL in Settings and your network connection.';
    return message.replaceFirst(
      RegExp(r'^(Bad state: |Exception: |Invalid argument[^:]*: )'),
      '',
    );
  }

  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      notice(friendlyError(e), NoticeKind.error);
    }
  }

  Future<void> initialize() async {
    state.initializing = true;
    state.initializationError = null;
    changed();
    try {
      await database.initialize();
      final device = await SettingsRepository(database).load('device');
      final storedUrl = device.values['backend_url'];
      if (storedUrl != null) connection.baseUrl = storedUrl;
      if (!_watchReady) {
        _watchReady = true;
        _subscriptions.add(
          watcher.notifications.listen((event) {
            if (state.activeFolder?.folderId != event.folderId) return;
            state.notifications.insert(0, event);
            state.unread++;
            state.highlighted.add(event.file.id);
            notice(
              'New file in ${event.directoryCode}: ${event.file.name} is now available.',
            );
            if (_localReady && settings.preferences.notifications)
              unawaited(perform(() => localNotifications.show(event)));
            unawaited(refresh());
            Timer(const Duration(seconds: 8), () {
              if (!_disposed) {
                state.highlighted.remove(event.file.id);
                changed();
              }
            });
            changed();
          }),
        );
        _subscriptions.add(
          watcher.errors.listen(
            (e) => notice(friendlyError(e), NoticeKind.warning),
          ),
        );
      }
      await _loadAccount();
      try {
        if (supportsDeviceNotifications) {
          await enableDeviceNotifications();
        } else {
          await refreshDevicePermission();
        }
      } catch (_) {
        devicePermission = 'Unavailable';
      }
    } catch (e) {
      state.initializationError = friendlyError(e);
    } finally {
      state.initializing = false;
      changed();
    }
  }

  Future<void> _loadAccount() async {
    final account = accountId;
    await Future.wait([saved.load(account), settings.load('device')]);
    if (accountId != account || _disposed) return;
    final id = settings.preferences.values['last_folder:$accountId'];
    if (settings.preferences.reopenLast && id != null) {
      for (final folder in saved.folders) {
        if (folder.folderId == id) {
          await openFolder(folder);
          break;
        }
      }
    }
  }

  Future<void> setBackendUrl(String value) async {
    if (state.connecting || transfersRunning || _queueRunning)
      throw StateError(
        'Wait for current transfers or connection changes to finish.',
      );
    final url = BackendConfig.normalize(value);
    state.connecting = true;
    changed();
    try {
      await SettingsRepository(database).set('device', 'backend_url', url);
      watcher.stop();
      _clearSession();
      connection.baseUrl = url;
      await _loadAccount();
      notice('Backend URL saved.', NoticeKind.success);
    } finally {
      state.connecting = false;
      changed();
    }
  }

  Future<void> testBackendUrl(String value) async {
    final candidate = BackendConnection(baseUrl: value);
    try {
      await candidate.checkHealth();
    } finally {
      await candidate.dispose();
    }
  }

  void _clearSession() {
    _lastAttemptedFolder = null;
    _generation++;
    _refresh++;
    state.activeFolder = null;
    state.files = [];
    state.selected.clear();
    state.highlighted.clear();
    state.notifications.clear();
    state.unread = 0;
    state.transfers.clear();
    state.error = null;
    state.loading = false;
    state.search = '';
    state.filter = const FileFilter();
    state.kind = FileKind.all;
    state.refreshedAt = null;
    saved.clear();
    settings.clear();
  }

  Future<SavedFolder> join(String code, String nickname, bool persist) async {
    final account = accountId;
    final folder = await directories.requireDirectory(code);
    if (accountId != account)
      throw StateError('Server changed. Please join again.');
    final record = SavedFolder.fromDirectory(
      account,
      folder,
      nickname: nickname.trim(),
      persisted: persist,
    );
    await saved.save(record);
    await openFolder(record);
    if (state.error != null) throw StateError(state.error!);
    notice('Folder joined.', NoticeKind.success);
    return record;
  }

  Future<SavedFolder> create(String nickname) async {
    final account = accountId;
    final folder = await directories.createDirectory();
    if (accountId != account)
      throw StateError('Server changed. Please create a folder again.');
    return SavedFolder.fromDirectory(
      account,
      folder,
      nickname: nickname.trim(),
    );
  }

  Future<void> retryFolder() async {
    final record = _lastAttemptedFolder;
    if (record != null) {
      await openFolder(record);
    } else {
      await refresh();
    }
  }

  Future<void> openFolder(SavedFolder record) async {
    if (record.accountId != accountId)
      throw StateError('Select the server that saved this folder.');
    _lastAttemptedFolder = record;
    final generation = ++_generation;
    ++_refresh;
    watcher.stop();
    state.selected.clear();
    state.files = [];
    state.highlighted.clear();
    state.activeFolder = null;
    state.refreshedAt = null;
    state.error = null;
    state.loading = true;
    changed();
    try {
      final folder = await directories.getById(record.folderId);
      final results = await files.getFiles(
        directoryCode: folder.code,
        folderId: folder.folderId,
      );
      if (generation != _generation || _disposed) return;
      state.activeFolder = folder;
      state.files = results;
      state.refreshedAt = DateTime.now();
      try {
        await saved.save(
          record.copyWith(
            code: folder.code,
            lastOpenedAt: DateTime.now(),
            lastValidatedAt: DateTime.now(),
          ),
        );
        if (record.persisted && generation == _generation)
          await settings.set('last_folder:$accountId', folder.folderId);
      } catch (e) {
        notice(
          'Folder opened, but local preferences could not be saved. ${friendlyError(e)}',
          NoticeKind.warning,
        );
      }
      if (generation == _generation) await _startWatcher();
    } catch (e) {
      if (generation == _generation)
        state.error =
            '${friendlyError(e)} Your saved connection has been kept. Reconnect, switch folders, or remove it in Settings.';
    } finally {
      if (generation == _generation) {
        state.loading = false;
        changed();
      }
    }
  }

  Future<void> refresh() async {
    final folder = state.activeFolder;
    if (folder == null) return;
    final generation = _generation, request = ++_refresh;
    state.loading = true;
    state.error = null;
    changed();
    try {
      final results = await files.getFiles(
        directoryCode: folder.code,
        folderId: folder.folderId,
      );
      if (generation != _generation || request != _refresh || _disposed) return;
      state.files = results;
      state.refreshedAt = DateTime.now();
      state.selected.removeWhere((id) => !results.any((f) => f.id == id));
    } catch (e) {
      if (generation == _generation && request == _refresh)
        state.error = friendlyError(e);
    } finally {
      if (generation == _generation && request == _refresh) {
        state.loading = false;
        changed();
      }
    }
  }

  Future<void> _startWatcher() async {
    watcher.stop();
    final folder = state.activeFolder;
    if (folder == null ||
        !settings.preferences.notifications ||
        activeSaved?.notificationsEnabled == false)
      return;
    try {
      await watcher.watch(folder.code, folderId: folder.folderId);
    } catch (e) {
      notice(
        'Folder is open. Notifications could not start: ${friendlyError(e)}',
        NoticeKind.warning,
      );
    }
  }

  Future<void> setPreference(String key, String value) async {
    await settings.set(key, value);
    if (key == 'notifications') await _startWatcher();
  }

  Future<void> updateFolder(SavedFolder folder) async {
    await saved.save(folder);
    if (folder.folderId == state.activeFolder?.folderId) await _startWatcher();
  }

  Future<void> removeFolder(SavedFolder folder) async {
    await saved.remove(folder);
    if (_lastAttemptedFolder?.folderId == folder.folderId)
      _lastAttemptedFolder = null;
    if (settings.preferences.values['last_folder:$accountId'] ==
        folder.folderId)
      await settings.set('last_folder:$accountId', '');
    if (state.activeFolder?.folderId == folder.folderId) {
      ++_generation;
      ++_refresh;
      watcher.stop();
      state.activeFolder = null;
      state.files = [];
      state.selected.clear();
      state.loading = false;
    }
    changed();
  }

  bool get supportsDeviceNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> refreshDevicePermission() async {
    if (!supportsDeviceNotifications) {
      devicePermission = 'In-app alerts only on this platform';
      changed();
      return;
    }
    await localNotifications.initialize(requestPermission: false);
    devicePermission = await localNotifications.permissionStatus();
    _localReady = devicePermission == 'Granted';
    changed();
  }

  Future<void> enableDeviceNotifications() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      devicePermission =
          'Device notifications are unavailable on this platform; in-app alerts remain available.';
      changed();
      return;
    }
    devicePermission = await localNotifications.initializeAndRequest();
    _localReady = devicePermission == 'Granted';
    changed();
  }

  List<DriveFileModel> get filteredFiles {
    final query = state.search.toLowerCase().trim();
    final filter = state.filter;
    final result = state.files
        .where(
          (f) =>
              (query.isEmpty ||
                  '${f.name} ${f.caption ?? ''}'.toLowerCase().contains(
                    query,
                  )) &&
              (state.kind == FileKind.all || fileKind(f) == state.kind) &&
              (filter.extensions.isEmpty ||
                  filter.extensions.contains(f.extension)) &&
              (filter.mimeTypes.isEmpty ||
                  filter.mimeTypes.contains(f.mimeType)) &&
              (filter.from == null ||
                  (f.createdAt != null &&
                      !f.createdAt!.isBefore(filter.from!))) &&
              (filter.to == null ||
                  (f.createdAt != null && !f.createdAt!.isAfter(filter.to!))),
        )
        .toList();
    result.sort((a, b) {
      if (state.sort == FileSort.name)
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (state.sort == FileSort.size)
        return (b.size ?? -1).compareTo(a.size ?? -1);
      if (a.createdAt == null) return b.createdAt == null ? 0 : 1;
      if (b.createdAt == null) return -1;
      return state.sort == FileSort.oldest
          ? a.createdAt!.compareTo(b.createdAt!)
          : b.createdAt!.compareTo(a.createdAt!);
    });
    return result;
  }

  void search(String value) {
    state.search = value;
    changed();
  }

  void setKind(FileKind kind) {
    state.kind = kind;
    changed();
  }

  void setFilter(FileFilter filter) {
    state.filter = filter;
    changed();
  }

  void setSort(FileSort sort) {
    state.sort = sort;
    changed();
  }

  void clearFilters() {
    state.search = '';
    state.kind = FileKind.all;
    state.filter = const FileFilter();
    state.sort = FileSort.newest;
    changed();
  }

  void select(String id, bool selected) {
    selected ? state.selected.add(id) : state.selected.remove(id);
    changed();
  }

  void selectAll(bool selected) {
    for (final f in filteredFiles) {
      selected ? state.selected.add(f.id) : state.selected.remove(f.id);
    }
    changed();
  }

  void markRead() {
    state.unread = 0;
    changed();
  }

  void enqueueUploads(List<PickedUpload> selected, DriveDirectory folder) {
    final account = accountId;
    for (final f in selected) {
      state.transfers.add(
        TransferJob.upload(
          accountId: account,
          folderId: folder.folderId,
          code: folder.code,
          name: f.name,
          bytes: f.bytes,
          caption: f.caption,
        ),
      );
    }
    changed();
    unawaited(_runQueue());
  }

  void downloadFiles(Iterable<DriveFileModel> files) {
    final folder = state.activeFolder;
    if (folder == null) return;
    for (final f in files) {
      state.transfers.add(
        TransferJob.download(
          accountId: accountId,
          folderId: folder.folderId,
          code: folder.code,
          source: f,
        ),
      );
    }
    changed();
    unawaited(_runQueue());
  }

  void stopRemaining() {
    for (final job in state.transfers) {
      if (job.status == TransferStatus.queued)
        job.status = TransferStatus.stopped;
    }
    changed();
  }

  void retry(TransferJob job) {
    if (job.accountId != accountId ||
        (job.status != TransferStatus.failed &&
            job.status != TransferStatus.stopped))
      return;
    job.status = TransferStatus.queued;
    job.error = null;
    job.transferred = 0;
    changed();
    unawaited(_runQueue());
  }

  void dismissCompleted() {
    state.transfers.removeWhere((j) => j.status == TransferStatus.complete);
    changed();
  }

  Future<void> _runQueue() async {
    if (_queueRunning || _disposed) return;
    _queueRunning = true;
    try {
      while (!_disposed) {
        final pending = state.transfers
            .where((j) => j.status == TransferStatus.queued)
            .toList();
        if (pending.isEmpty) break;
        final job = pending.first;
        if (accountId != job.accountId) {
          job.status = TransferStatus.stopped;
          continue;
        }
        job.status = TransferStatus.running;
        changed();
        void progress(int n, int? total) {
          job.transferred = n;
          job.total = total;
          changed();
        }

        try {
          if (job.upload) {
            job.uploadId ??= await uploads.reserveId();
            if (job.accountId != accountId || _disposed)
              throw StateError('Server changed.');
            await uploads.uploadBytes(
              folderId: job.folderId,
              code: job.code,
              name: job.name,
              bytes: job.bytes!,
              caption: job.caption,
              mimeType: job.name.toLowerCase().endsWith('.txt')
                  ? 'text/plain'
                  : null,
              uploadId: job.uploadId,
              onProgress: progress,
            );
            job.bytes = null;
          } else {
            job.localPath = await downloads.download(
              directoryCode: job.code,
              folderId: job.folderId,
              fileId: job.file!.id,
              onProgress: progress,
            );
          }
          job.status = TransferStatus.complete;
          if (job.accountId != accountId || _disposed) continue;
          notice(
            job.upload
                ? 'Upload complete — ${job.name} is available in ${job.code}.'
                : (kIsWeb
                      ? 'Download received — ${job.localPath}'
                      : 'Download complete — ${job.localPath}'),
            NoticeKind.success,
          );
          if (job.upload && state.activeFolder?.folderId == job.folderId) {
            await refresh();
            await watcher.checkNow();
          }
        } catch (e) {
          job.status = TransferStatus.failed;
          job.error = friendlyError(e);
          if (job.accountId != accountId || _disposed) continue;
          notice(
            'Transfer failed: ${job.name}. ${job.error}',
            NoticeKind.error,
          );
        }
        changed();
      }
    } finally {
      _queueRunning = false;
      changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    ++_refresh;
    watcher.stop();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    unawaited(watcher.dispose());
    unawaited(connection.dispose());
    unawaited(database.close());
    unawaited(_notices.close());
    saved.removeListener(changed);
    settings.removeListener(changed);
    saved.dispose();
    settings.dispose();
    super.dispose();
  }
}
