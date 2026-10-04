import 'package:flutter/material.dart';

class AppProgress extends StatelessWidget {
  final double? value;
  final bool circular;
  final String label;
  const AppProgress({
    super.key,
    this.value,
    this.circular = false,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) && value == null) {
      return Semantics(
        label: '$label, in progress',
        liveRegion: true,
        child: circular
            ? const Icon(Icons.hourglass_top, size: 24)
            : const SizedBox(
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF2563EB)),
                ),
              ),
      );
    }
    return circular
        ? CircularProgressIndicator(
            value: value,
            strokeWidth: 2,
            semanticsLabel: label,
          )
        : LinearProgressIndicator(value: value, semanticsLabel: label);
  }
}
