import 'dart:async';
import 'package:flutter/material.dart';
import '../models/file_filter.dart';
import '../state/drive_ui_controller.dart';
import '../state/drive_ui_state.dart';
import '../utils/date_group_helper.dart';
import '../utils/file_type_mapper.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/layout/home_header.dart';
import '../widgets/layout/folder_summary.dart';
import '../widgets/folders/join_create_folder_popup.dart';
import '../widgets/files/file_search_field.dart';
import '../widgets/files/file_filter_popup.dart';
import '../widgets/files/selection_toolbar.dart';
import '../widgets/files/date_group_section.dart';
import '../widgets/feedback/app_toast.dart';
import '../widgets/feedback/empty_state.dart';
import '../widgets/feedback/error_state.dart';
import '../widgets/feedback/loading_skeleton.dart';
import '../widgets/transfers/transfer_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  final DriveUiController controller;
  const HomeScreen({super.key, required this.controller});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<UiNotice>? notices;
  @override
  void initState() {
    super.initState();
    notices = widget.controller.notices.listen((notice) {
      if (mounted) AppToast.show(context, notice);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.state.activeFolder == null)
        JoinCreateFolderPopup.show(context, widget.controller);
    });
  }

  @override
  void dispose() {
    notices?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller, s = widget.controller.state;
      final filter = s.filter;
      final groups = groupFilesByDate(c.filteredFiles);
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveLayout.isMobile(context) ? 16 : 32,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HomeHeader(controller: c),
                              if (s.error != null)
                                ErrorState(
                                  message: s.error!,
                                  retry: () => c.perform(
                                    s.activeFolder == null
                                        ? c.retryFolder
                                        : c.refresh,
                                  ),
                                ),
                              if (s.activeFolder == null && !s.loading)
                                EmptyState(
                                  title: 'A home for your shared files',
                                  message:
                                      'Create a folder or join one with a six-character code.',
                                  actions: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () =>
                                            JoinCreateFolderPopup.show(
                                              context,
                                              c,
                                            ),
                                        icon: const Icon(Icons.login),
                                        label: const Text('Join folder'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            JoinCreateFolderPopup.show(
                                              context,
                                              c,
                                              create: true,
                                            ),
                                        icon: const Icon(
                                          Icons.create_new_folder_outlined,
                                        ),
                                        label: const Text('Create folder'),
                                      ),
                                    ],
                                  ),
                                ),
                              if (s.activeFolder != null) ...[
                                FolderSummary(controller: c),
                                const SizedBox(height: 28),
                                Text(
                                  'Files',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                FileSearchField(
                                  value: s.search,
                                  onChanged: c.search,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    for (final kind in FileKind.values)
                                      ChoiceChip(
                                        label: Text(kindLabel(kind)),
                                        selected: s.kind == kind,
                                        onSelected: (_) => c.setKind(kind),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () => showAdaptivePopup<void>(
                                        context,
                                        FileFilterPopup(controller: c),
                                      ),
                                      icon: const Icon(Icons.tune),
                                      label: const Text('Filters & sort'),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (s.search.isNotEmpty)
                                      InputChip(
                                        label: Text('Search: ${s.search}'),
                                        onDeleted: () => c.search(''),
                                      ),
                                    if (s.kind != FileKind.all)
                                      InputChip(
                                        label: Text(kindLabel(s.kind)),
                                        onDeleted: () =>
                                            c.setKind(FileKind.all),
                                      ),
                                    for (final ext in filter.extensions)
                                      InputChip(
                                        label: Text(ext.toUpperCase()),
                                        onDeleted: () => c.setFilter(
                                          FileFilter(
                                            from: filter.from,
                                            to: filter.to,
                                            extensions: {...filter.extensions}
                                              ..remove(ext),
                                          ),
                                        ),
                                      ),
                                    if (filter.from != null)
                                      InputChip(
                                        label: Text('From ${filter.from}'),
                                        onDeleted: () => c.setFilter(
                                          FileFilter(
                                            to: filter.to,
                                            extensions: filter.extensions,
                                          ),
                                        ),
                                      ),
                                    if (filter.to != null)
                                      InputChip(
                                        label: Text('To ${filter.to}'),
                                        onDeleted: () => c.setFilter(
                                          FileFilter(
                                            from: filter.from,
                                            extensions: filter.extensions,
                                          ),
                                        ),
                                      ),
                                    if (s.sort != FileSort.newest)
                                      InputChip(
                                        label: Text('Sort: ${s.sort.name}'),
                                        onDeleted: () =>
                                            c.setSort(FileSort.newest),
                                      ),
                                    TextButton(
                                      onPressed: c.clearFilters,
                                      child: const Text('Clear filters'),
                                    ),
                                  ],
                                ),
                                SelectionToolbar(controller: c),
                                if (!s.loading && c.filteredFiles.isEmpty)
                                  EmptyState(
                                    title: s.files.isEmpty
                                        ? 'This folder is ready for files'
                                        : 'No matching files',
                                    message: s.files.isEmpty
                                        ? 'Use Share files to upload or write a text file.'
                                        : 'Try a different search or clear your filters.',
                                  ),
                                for (final group in groups.values)
                                  DateGroupSection(files: group, controller: c),
                              ],
                              if (s.loading) const LoadingSkeleton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TransferProgressBar(controller: c),
            ],
          ),
        ),
      );
    },
  );
}
