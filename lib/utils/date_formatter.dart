import 'package:intl/intl.dart';

String formatTimestamp(DateTime? value, {bool use24Hour = false}) {
  if (value == null) return 'Date unavailable';
  final local = value.toLocal();
  return '${DateFormat('EEEE, d MMMM yyyy').format(local)} at ${DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(local)}';
}

String dateHeading(DateTime? value, {bool relative = true, DateTime? now}) {
  if (value == null) return 'Date unavailable';
  final d = value.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  // UTC surrogates represent local calendar days without daylight-saving hour offsets.
  final days = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(d.year, d.month, d.day)).inDays;
  final date = DateFormat('EEEE, d MMMM yyyy').format(d);
  final prefix = switch (days) {
    0 => 'Today',
    1 => 'Yesterday',
    2 => '2 days ago',
    3 => '3 days ago',
    _ => '',
  };
  return relative && prefix.isNotEmpty ? '$prefix — $date' : date;
}
