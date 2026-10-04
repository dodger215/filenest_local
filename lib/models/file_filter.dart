class FileFilter {
  final DateTime? from;
  final DateTime? to;
  final Set<String> extensions;
  final Set<String> mimeTypes;

  /// `from` and `to` are inclusive instants in the device's time zone or UTC.
  const FileFilter({
    this.from,
    this.to,
    this.extensions = const {},
    this.mimeTypes = const {},
  });
}
