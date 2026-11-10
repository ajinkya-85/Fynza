import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../core/utils/relative_time_formatter.dart';
import '../view_models/backup_view_model.dart';
import '../widgets/backup_info_dialog.dart';
import '../widgets/frequency_dialog.dart';
import '../widgets/restore_bottom_sheet.dart';
import '../widgets/restore_confirm_dialog.dart';

class DataAndStorageView extends ConsumerWidget {
  const DataAndStorageView({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showRestoreDialog(
    BuildContext context,
    WidgetRef ref, {
    required dynamic inspectResult,
  }) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => RestoreConfirmDialog(
        summary: inspectResult.summary,
        fileName: inspectResult.fileName,
        onConfirm: () {
          ref
              .read(backupViewModelProvider.notifier)
              .restoreBackup(
                inspectResult.bytes,
                summary: inspectResult.summary,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(backupViewModelProvider);
    final viewModel = ref.read(backupViewModelProvider.notifier);

    // Listen to success and error messages
    ref.listen<BackupUiState>(backupViewModelProvider, (previous, next) {
      if (next.userErrorMessage != null &&
          next.userErrorMessage != previous?.userErrorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.userErrorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        viewModel.clearMessages();
      } else if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        viewModel.clearMessages();
      }
    });

    final lastBackupText = RelativeTimeFormatter.format(state.lastAutoBackupAt);

    return PopScope(
      canPop: !state.isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data and storage'),
          actions: [
            IconButton(
              tooltip: 'Help and information',
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const BackupInfoDialog(),
                );
              },
            ),
          ],
          bottom: state.isBusy
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Column(
                    children: [
                      const LinearProgressIndicator(),
                      if (state.busyStatus != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            state.busyStatus!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : null,
        ),
        body: FadingScrollBoundary(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 1. Storage location
              ListTile(
                leading: Icon(
                  Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Storage location'),
                subtitle: Text(
                  state.backupDirectoryPath.isEmpty
                      ? 'Loading...'
                      : state.backupDirectoryPath,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: state.backupDirectoryPath.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(
                          ClipboardData(text: state.backupDirectoryPath),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Storage path copied to clipboard'),
                          ),
                        );
                      },
              ),

              // Storage info row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Used for automatic backups. They are deleted if the app is uninstalled, so use Create backup to save a copy elsewhere.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Section: Backup and restore
              _SectionHeader(label: 'Backup and restore'),

              const SizedBox(height: 8),

              // Joined pill button pair
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: state.isBusy
                          ? theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            )
                          : theme.colorScheme.outline,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Create backup
                        Expanded(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const RoundedRectangleBorder(),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                            onPressed: state.isBusy
                                ? null
                                : () => viewModel.createManualBackup(),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text(
                              'Create backup',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: state.isBusy
                              ? theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                )
                              : theme.colorScheme.outline,
                        ),
                        // Restore backup
                        Expanded(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const RoundedRectangleBorder(),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                            onPressed: state.isBusy
                                ? null
                                : () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => RestoreBottomSheet(
                                        autoBackups: state.autoBackups,
                                        onPickFile: () async {
                                          final res = await viewModel
                                              .pickAndInspectBackupFile();
                                          if (res != null && context.mounted) {
                                            _showRestoreDialog(
                                              context,
                                              ref,
                                              inspectResult: res,
                                            );
                                          }
                                        },
                                        onSelectAutoBackup: (file) async {
                                          final res = await viewModel
                                              .inspectExistingFile(file);
                                          if (res != null && context.mounted) {
                                            _showRestoreDialog(
                                              context,
                                              ref,
                                              inspectResult: res,
                                            );
                                          }
                                        },
                                        onShareAutoBackup: (file) =>
                                            viewModel.shareAutoBackup(file),
                                        onDeleteAutoBackup: (file) =>
                                            viewModel.deleteAutoBackup(file),
                                      ),
                                    );
                                  },
                            icon: const Icon(
                              Icons.settings_backup_restore_outlined,
                            ),
                            label: const Text(
                              'Restore backup',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Frequency ListTile
              ListTile(
                title: const Text('Automatic backup frequency'),
                subtitle: Text(state.frequency.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: state.isBusy
                    ? null
                    : () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => FrequencyDialog(
                            currentFrequency: state.frequency,
                            onSelected: (freq) => viewModel.setFrequency(freq),
                          ),
                        );
                      },
              ),

              // Warning and relative time info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keep copies of backups in other places as well. Backups contain your financial data; be careful if sharing.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last automatically backed up: $lastBackupText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Section: Storage usage
              _SectionHeader(label: 'Storage usage'),

              ListTile(
                leading: Icon(
                  Icons.data_usage_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Automatic backups'),
                subtitle: Text(
                  '${state.storageFileCount} files, ${_formatBytes(state.storageUsageBytes)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
