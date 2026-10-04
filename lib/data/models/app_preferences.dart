import 'package:flutter/material.dart';

class AppPreferences {
  final Map<String, String> values;
  const AppPreferences([this.values = const {}]);
  String? get lastFolderId => values['last_folder'];
  bool get reopenLast => values['reopen_last'] != 'false';
  bool get notifications => values['notifications'] != 'false';
  bool get grid => values['view'] == 'grid';
  bool get use24Hour => values['time'] == '24';
  bool get relativeDates => values['relative_dates'] != 'false';
  ThemeMode get theme => switch (values['theme']) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
