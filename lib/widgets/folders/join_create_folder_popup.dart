import '../feedback/app_progress.dart';
import 'package:flutter/material.dart';
import '../../state/drive_ui_controller.dart';
import '../../state/drive_ui_state.dart';
import '../../data/models/saved_folder.dart';
import '../layout/responsive_layout.dart';
import 'join_folder_form.dart';
import 'create_folder_form.dart';
import 'generated_code_card.dart';

class JoinCreateFolderPopup extends StatefulWidget {
  final DriveUiController controller;
  final bool create;
  const JoinCreateFolderPopup({
    super.key,
    required this.controller,
    this.create = false,
  });
  static Future<void> show(
    BuildContext context,
    DriveUiController c, {
    bool create = false,
  }) => showAdaptivePopup<void>(
    context,
    JoinCreateFolderPopup(controller: c, create: create),
    dismissible: false,
  );
  @override
  State<JoinCreateFolderPopup> createState() => _JoinCreateFolderPopupState();
}

class _JoinCreateFolderPopupState extends State<JoinCreateFolderPopup> {
  final code = TextEditingController(), nickname = TextEditingController();
  late bool create = widget.create;
  bool save = true, busy = false, saved = false;
  String? error;
  SavedFolder? created;
  @override
  void dispose() {
    code.dispose();
    nickname.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = DriveUiController.friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> persistCreated() async {
    await widget.controller.saved.save(created!);
    if (mounted) setState(() => saved = true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return PopScope(
        canPop: !busy && (created == null || saved),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Join a shared folder',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: busy || (created != null && !saved)
                      ? null
                      : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (created == null) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Join folder'),
                    icon: Icon(Icons.login),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Create folder'),
                    icon: Icon(Icons.create_new_folder_outlined),
                  ),
                ],
                selected: {create},
                onSelectionChanged: busy
                    ? null
                    : (v) => setState(() {
                        create = v.single;
                        error = null;
                      }),
              ),
              const SizedBox(height: 16),
              Text('Server: ${c.connection.baseUrl}'),
              const Text('Change the backend URL in Settings.'),
              const SizedBox(height: 16),
              AnimatedSize(
                duration: ResponsiveLayout.duration(context),
                child: AnimatedSwitcher(
                  duration: ResponsiveLayout.duration(context),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: create
                      ? CreateFolderForm(
                          key: const ValueKey('create'),
                          nickname: nickname,
                          ready: !c.state.connecting,
                          busy: busy,
                          submit: () => run(() async {
                            created = await c.create(nickname.text);
                            if (mounted) setState(() {});
                            await persistCreated();
                            c.notice('Folder created.', NoticeKind.success);
                          }),
                        )
                      : JoinFolderForm(
                          key: const ValueKey('join'),
                          code: code,
                          nickname: nickname,
                          save: save,
                          ready: !c.state.connecting,
                          busy: busy,
                          onSave: (v) => setState(() => save = v),
                          onChanged: () {
                            if (mounted) setState(() {});
                          },
                          submit: () => run(() async {
                            await c.join(code.text, nickname.text, save);
                            if (mounted) {
                              setState(() => busy = false);
                              Navigator.pop(context);
                            }
                          }),
                        ),
                ),
              ),
            ] else
              GeneratedCodeCard(
                folder: created!,
                saved: saved,
                busy: busy,
                controller: c,
                retrySaving: () => run(persistCreated),
                useFolder: () => run(() async {
                  await c.openFolder(created!);
                  if (c.state.error != null) throw StateError(c.state.error!);
                  if (mounted) {
                    setState(() => busy = false);
                    Navigator.pop(context);
                  }
                }),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: AppProgress(label: 'Working with the server'),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
