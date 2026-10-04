import '../models/drive_file.dart';

/// Keys are local calendar dates: YYYY-MM-DD. Keeps the file objects intact.
Map<String, List<DriveFileModel>> groupFilesByDate(
  Iterable<DriveFileModel> files,
) {
  final groups = <String, List<DriveFileModel>>{};
  for (final file in files) {
    final d = file.createdAt?.toLocal();
    final key = d == null
        ? 'Unknown'
        : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    groups.putIfAbsent(key, () => []).add(file);
  }
  return groups;
}
