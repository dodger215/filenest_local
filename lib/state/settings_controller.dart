import 'package:flutter/foundation.dart';
import '../data/models/app_preferences.dart';
import '../data/repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  final SettingsRepository repository;
  String? accountId;
  AppPreferences preferences = const AppPreferences();
  SettingsController(this.repository);
  Future<void> load(String account) async {
    accountId = account;
    preferences = const AppPreferences();
    final result = await repository.load(account);
    if (accountId == account) {
      preferences = result;
      notifyListeners();
    }
  }

  Future<void> set(String key, String value) async {
    final account = accountId;
    if (account == null)
      throw StateError('Local settings are not initialized.');
    await repository.set(account, key, value);
    if (accountId != account) return;
    preferences = AppPreferences({...preferences.values, key: value});
    notifyListeners();
  }

  void clear() {
    accountId = null;
    preferences = const AppPreferences();
    notifyListeners();
  }
}
