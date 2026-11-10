import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_alert_provider.dart';

class AppAlertHost extends ConsumerWidget {
  const AppAlertHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(appAlertProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom + 88;

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottom,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Updates',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Clear updates',
                      button: true,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: ref.read(appAlertProvider.notifier).clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                  itemCount: alerts.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final color = switch (alert.tone) {
                      AppAlertTone.information => theme.colorScheme.primary,
                      AppAlertTone.success => theme.colorScheme.tertiary,
                      AppAlertTone.error => theme.colorScheme.error,
                    };
                    final icon = switch (alert.tone) {
                      AppAlertTone.information => Icons.info_outline_rounded,
                      AppAlertTone.success => Icons.check_circle_outline,
                      AppAlertTone.error => Icons.error_outline_rounded,
                    };

                    return Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alert.message,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (alert.actionLabel != null && alert.onAction != null)
                          TextButton(
                            onPressed: () {
                              alert.onAction!();
                              ref
                                  .read(appAlertProvider.notifier)
                                  .dismiss(alert.id);
                            },
                            child: Text(alert.actionLabel!),
                          )
                        else
                          Semantics(
                            label: 'Dismiss update',
                            button: true,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => ref
                                  .read(appAlertProvider.notifier)
                                  .dismiss(alert.id),
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
