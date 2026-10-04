import 'package:flutter/foundation.dart';
import '../data/models/saved_folder.dart';
import '../data/repositories/saved_folder_repository.dart';

class SavedFoldersController extends ChangeNotifier {
  final SavedFolderRepository repository;
  String? accountId;
  List<SavedFolder> folders = [];
  SavedFoldersController(this.repository);
  Future<void> load(String account) async {
    accountId = account;
    folders = [];
    final result = await repository.load(account);
    if (accountId == account) {
      folders = result;
      notifyListeners();
    }
  }

  Future<void> save(SavedFolder folder) async {
    if (folder.persisted) await repository.save(folder);
    if (accountId != folder.accountId) return;
    folders = [...folders.where((f) => f.folderId != folder.folderId), folder];
    notifyListeners();
  }

  Future<void> remove(SavedFolder folder) async {
    await repository.remove(folder.accountId, folder.folderId);
    if (accountId != folder.accountId) return;
    folders = folders.where((f) => f.folderId != folder.folderId).toList();
    notifyListeners();
  }

  void clear() {
    accountId = null;
    folders = [];
    notifyListeners();
  }
}
