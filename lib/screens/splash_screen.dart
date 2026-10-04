import '../widgets/feedback/app_progress.dart';
import 'package:flutter/material.dart';
import '../state/drive_ui_controller.dart';
import '../widgets/branding/filenest_logo.dart';
import '../widgets/feedback/error_state.dart';
import '../widgets/layout/responsive_layout.dart';

class SplashScreen extends StatelessWidget {
  final DriveUiController controller;
  const SplashScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: ResponsiveLayout.duration(context),
                  tween: Tween(begin: .85, end: 1),
                  builder: (_, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(scale: value, child: child),
                  ),
                  child: const FileNestLogo(size: 96),
                ),
                const SizedBox(height: 24),
                Text(
                  'FileNest',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('One code. Your shared files.'),
                const SizedBox(height: 32),
                if (controller.state.initializationError != null)
                  ErrorState(
                    message: controller.state.initializationError!,
                    retry: controller.initialize,
                  )
                else
                  const AppProgress(
                    circular: true,
                    label: 'Initializing FileNest',
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
