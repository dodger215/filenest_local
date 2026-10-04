import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../state/drive_ui_controller.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import 'app_theme.dart';

class FileNestApp extends StatefulWidget {
  final DriveUiController? controller;
  final String? backendUrl;
  const FileNestApp({super.key, this.controller, this.backendUrl});
  @override
  State<FileNestApp> createState() => _FileNestAppState();
}

class _FileNestAppState extends State<FileNestApp> {
  late final controller =
      widget.controller ?? DriveUiController(backendUrl: widget.backendUrl);
  @override
  void initState() {
    super.initState();
    unawaited(controller.initialize());
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      title: 'FileNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: controller.settings.preferences.theme,
      themeAnimationDuration:
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home:
          controller.state.initializing ||
              controller.state.initializationError != null
          ? SplashScreen(controller: controller)
          : HomeScreen(controller: controller),
    ),
  );
}
