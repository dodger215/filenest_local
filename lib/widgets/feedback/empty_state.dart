import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title, message;
  final Widget? actions;
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        Icon(
          Icons.folder_open_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (actions != null) ...[const SizedBox(height: 24), actions!],
      ],
    ),
  );
}
