import 'package:flutter/material.dart';
import '../layout/responsive_layout.dart';

class AnimatedSuccessIcon extends StatelessWidget {
  const AnimatedSuccessIcon({super.key});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .85, end: 1),
    duration: ResponsiveLayout.duration(context),
    builder: (context, value, child) => Transform.scale(
      scale: value,
      child: Opacity(opacity: value, child: child),
    ),
    child: const Stack(
      alignment: Alignment.bottomRight,
      children: [
        Icon(Icons.folder_rounded, size: 88, color: Color(0xFF2563EB)),
        Icon(Icons.check_circle, size: 34, color: Color(0xFF16A34A)),
      ],
    ),
  );
}
