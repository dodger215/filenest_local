import 'package:flutter/material.dart';
import '../../state/drive_ui_state.dart';

class AppToast {
  static void show(BuildContext context, UiNotice notice) {
    final color = switch (notice.kind) {
      NoticeKind.success => const Color(0xFF166534),
      NoticeKind.warning => const Color(0xFF854D0E),
      NoticeKind.error => const Color(0xFFB91C1C),
      NoticeKind.information => const Color(0xFF1E40AF),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notice.message),
        backgroundColor: color,
        showCloseIcon: true,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
