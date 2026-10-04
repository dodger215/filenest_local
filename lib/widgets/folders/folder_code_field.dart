import 'package:flutter/material.dart';
import '../../services/clipboard_service.dart';

/// One editable, screen-reader accessible input with six visual positions.
class FolderCodeField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged, onSubmit;
  const FolderCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
  });
  @override
  State<FolderCodeField> createState() => _FolderCodeFieldState();
}

class _FolderCodeFieldState extends State<FolderCodeField> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    focus.addListener(changed);
    widget.controller.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    focus.removeListener(changed);
    focus.dispose();
    super.dispose();
  }

  bool get isSixCode =>
      widget.controller.text.length <= 6 &&
      !widget.controller.text.contains('http') &&
      !widget.controller.text.contains('/');

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final useVisualBoxes = isSixCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Folder code'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: useVisualBoxes
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ExcludeSemantics(
                              child: Row(
                                children: [
                                  for (var i = 0; i < 6; i++)
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          right: i == 5 ? 0 : 6,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          border: Border.all(
                                            width: focus.hasFocus ? 2 : 1,
                                            color: focus.hasFocus
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            text.length > i ? text[i] : '·',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontFamily: 'monospace',
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: focus,
                              enabled: widget.enabled,
                              showCursor: false,
                              textCapitalization: TextCapitalization.characters,
                              enableSuggestions: false,
                              autocorrect: false,
                              style: const TextStyle(color: Colors.transparent),
                              keyboardType: TextInputType.visiblePassword,
                              decoration: const InputDecoration(
                                labelText: 'Folder code or link',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                labelStyle: TextStyle(
                                  color: Colors.transparent,
                                ),
                                counterText: '',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              onChanged: (_) => widget.onChanged(),
                              onSubmitted: (_) => widget.onSubmit(),
                            ),
                          ),
                        ],
                      )
                    : TextField(
                        controller: widget.controller,
                        focusNode: focus,
                        enabled: widget.enabled,
                        decoration: InputDecoration(
                          hintText: 'Enter folder code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => widget.onChanged(),
                        onSubmitted: (_) => widget.onSubmit(),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Paste code or link',
              onPressed: !widget.enabled
                  ? null
                  : () async {
                      try {
                        final value = (await ClipboardService.paste()).trim();
                        if (!mounted) return;
                        widget.controller.text = value;
                        widget.onChanged();
                        focus.requestFocus();
                      } catch (_) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Clipboard unavailable. Type or paste into the field.',
                              ),
                            ),
                          );
                      }
                    },
              icon: const Icon(Icons.content_paste),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enter a 6-character code (e.g. 8CA75J)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
