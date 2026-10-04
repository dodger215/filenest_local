import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/clipboard_service.dart';
import '../layout/responsive_layout.dart';

class CopyCodeButton extends StatefulWidget {
  final String code;
  const CopyCodeButton({super.key, required this.code});
  @override
  State<CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<CopyCodeButton> {
  bool copied = false;
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () async {
      try {
        await ClipboardService.copy(widget.code);
        if (!mounted) return;
        setState(() => copied = true);
        timer?.cancel();
        timer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => copied = false);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code copied.')));
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard unavailable. Select and copy the code.'),
            ),
          );
      }
    },
    icon: AnimatedSwitcher(
      duration: ResponsiveLayout.duration(context),
      child: Icon(
        copied ? Icons.check : Icons.copy_outlined,
        key: ValueKey(copied),
      ),
    ),
    label: Text(copied ? 'Copied!' : 'Copy code'),
  );
}
