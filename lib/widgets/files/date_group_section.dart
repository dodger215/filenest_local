import 'package:flutter/material.dart';
import '../../models/drive_file.dart';
import '../../state/drive_ui_controller.dart';
import '../../utils/date_formatter.dart';
import 'file_card.dart';
import 'file_table.dart';

class DateGroupSection extends StatelessWidget {
  final List<DriveFileModel> files;
  final DriveUiController controller;
  const DateGroupSection({
    super.key,
    required this.files,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
        child: Text(
          dateHeading(
            files.first.createdAt,
            relative: controller.settings.preferences.relativeDates,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1000 &&
              !controller.settings.preferences.grid &&
              MediaQuery.textScalerOf(context).scale(1) < 1.5)
            return FileTable(files: files, controller: controller);
          final columns =
              controller.settings.preferences.grid &&
                  constraints.maxWidth >= 650
              ? (constraints.maxWidth >= 1050 ? 3 : 2)
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final file in files)
                SizedBox(
                  width: width,
                  child: FileCard(file: file, controller: controller),
                ),
            ],
          );
        },
      ),
    ],
  );
}
