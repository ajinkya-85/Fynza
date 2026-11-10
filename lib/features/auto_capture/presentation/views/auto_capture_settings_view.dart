import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../domain/models/capture_status.dart';
import '../view_models/auto_capture_settings_view_model.dart';
import 'parser_playground_view.dart';

class AutoCaptureSettingsView extends ConsumerStatefulWidget {
  const AutoCaptureSettingsView({super.key});

  @override
  ConsumerState<AutoCaptureSettingsView> createState() =>
      _AutoCaptureSettingsViewState();
}

class _AutoCaptureSettingsViewState
    extends ConsumerState<AutoCaptureSettingsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref
          .read(autoCaptureSettingsViewModelProvider.notifier)
          .refreshPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(autoCaptureSettingsViewModelProvider);
    final viewModel = ref.read(autoCaptureSettingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-Capture SMS')),
      body: FadingScrollBoundary(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(context, state, viewModel),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Auto-Capture'),
              subtitle: const Text(
                'Detect bank SMS notifications on this device',
              ),
              value: state.isMasterEnabled,
              onChanged: (val) => viewModel.setMasterEnabled(val),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Capture Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            RadioGroup<CaptureMode>(
              groupValue: state.mode,
              onChanged: (val) {
                if (state.isMasterEnabled && val != null) {
                  viewModel.setMode(val);
                }
              },
              child: Column(
                children: [
                  RadioListTile<CaptureMode>(
                    title: const Text('Review first (Recommended)'),
                    subtitle: const Text(
                      'New transactions stay in inbox until you confirm them',
                    ),
                    value: CaptureMode.reviewFirst,
                    enabled: state.isMasterEnabled,
                  ),
                  RadioListTile<CaptureMode>(
                    title: const Text('Add automatically'),
                    subtitle: const Text(
                      'High-confidence transactions with known category are added directly. (Undo is available)',
                    ),
                    value: CaptureMode.addAutomatically,
                    enabled: state.isMasterEnabled,
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Test with a pasted message'),
              subtitle: const Text('Try out the SMS parser in the playground'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ParserPlaygroundView(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.battery_charging_full_outlined),
              title: const Text('Battery optimization help'),
              subtitle: const Text(
                'Ensure background notification capture works reliably',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showBatteryHelpDialog(context),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Ignored Senders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.ignoredSenders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No ignored senders. You can ignore senders from the inbox.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...state.ignoredSenders.map(
                (sender) => ListTile(
                  title: Text(sender),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove from ignored',
                    onPressed: () => viewModel.removeIgnoredSender(sender),
                  ),
                ),
              ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete all captured data',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: const Text('Removes all inbox items and logs'),
              onTap: () => _showDeleteConfirmDialog(context, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    AutoCaptureSettingsState state,
    AutoCaptureSettingsViewModel vm,
  ) {
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;
    IconData statusIcon;
    String statusDesc;

    if (!state.isMasterEnabled) {
      statusText = 'Disabled by you';
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.pause_circle_outline;
      statusDesc =
          'Auto-capture is turned off. Toggle the switch below to enable it.';
    } else if (!state.isPermissionGranted) {
      statusText = 'Permission needed';
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.warning_amber_rounded;
      statusDesc =
          'Notification access is required to read bank SMS notifications.';
    } else {
      statusText = 'Active';
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.check_circle_outline;
      statusDesc =
          'Listening for bank SMS notifications from default SMS apps.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.isMasterEnabled && !state.isPermissionGranted) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _showPermissionExplanationDialog(context, vm),
                child: const Text('Grant Notification Access'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPermissionExplanationDialog(
    BuildContext context,
    AutoCaptureSettingsViewModel vm,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Access'),
        content: const Text(
          'Fynza only reads notifications from SMS apps when they contain transaction keywords (INR / Rs). '
          'Your messages are processed purely on this device and are never uploaded or stored raw.\n\n'
          'Android may show a general system warning about reading all notifications. You can revoke access at any time in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vm.requestPermission();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showBatteryHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Battery Settings'),
        content: const Text(
          'Some phone manufacturers aggressively stop background services.\n\n'
          'To ensure notifications are captured when the app is closed:\n'
          '1. Go to System Settings > Apps\n'
          '2. Select Fynza\n'
          '3. Tap Battery (or App battery usage)\n'
          '4. Select "Unrestricted"',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    AutoCaptureSettingsViewModel vm,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Captured Data?'),
        content: const Text(
          'This will delete all pending and auto-added capture records. Confirmed transactions already added to your expense list will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await vm.deleteAllCapturedData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Captured data deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
