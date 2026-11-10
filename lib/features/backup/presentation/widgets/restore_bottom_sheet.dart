import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/backup_file_info.dart';

class RestoreBottomSheet extends StatelessWidget {
  final List<BackupFileInfo> autoBackups;
  final VoidCallback onPickFile;
  final ValueChanged<File> onSelectAutoBackup;
  final ValueChanged<File> onShareAutoBackup;
  final ValueChanged<File> onDeleteAutoBackup;

  const RestoreBottomSheet({
    super.key,
    required this.autoBackups,
    required this.onPickFile,
    required this.onSelectAutoBackup,
    required this.onShareAutoBackup,
    required this.onDeleteAutoBackup,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Restore Backup',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.file_open_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Choose a file...'),
                    subtitle: const Text('Browse device or cloud storage'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop();
                      onPickFile();
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'AUTOMATIC BACKUPS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (autoBackups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No automatic backups yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...autoBackups.map((info) {
                      final dateStr = DateFormat.yMMMd().add_jm().format(
                        info.modifiedAt,
                      );
                      final sizeStr = _formatFileSize(info.sizeBytes);

                      return ListTile(
                        leading: Icon(
                          Icons.history_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('$sizeStr • ${info.name}'),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectAutoBackup(File(info.path));
                        },
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'restore':
                                Navigator.of(context).pop();
                                onSelectAutoBackup(File(info.path));
                                break;
                              case 'share':
                                onShareAutoBackup(File(info.path));
                                break;
                              case 'delete':
                                onDeleteAutoBackup(File(info.path));
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  Icon(Icons.restore),
                                  SizedBox(width: 8),
                                  Text('Restore'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined),
                                  SizedBox(width: 8),
                                  Text('Share'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
