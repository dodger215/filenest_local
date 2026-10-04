import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

Future<Database> openLocalDatabase(OpenDatabaseOptions options) async {
  final DatabaseFactory factory;
  if (Platform.isLinux || Platform.isWindows) {
    ffi.sqfliteFfiInit();
    factory = ffi.databaseFactoryFfi;
  } else {
    factory = mobile.databaseFactory;
  }
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return factory.openDatabase(
    p.join(dir.path, 'filenest.sqlite'),
    options: options,
  );
}
