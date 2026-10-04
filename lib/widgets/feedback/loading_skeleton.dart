import 'app_progress.dart';
import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading files',
    child: Column(
      children: [
        const AppProgress(label: 'Loading folder'),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          Card(
            child: SizedBox(
              height: 84,
              child: Center(
                child: Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
