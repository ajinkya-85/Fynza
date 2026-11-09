import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/capture_constants.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../auto_capture/data/services/capture_preferences_service.dart';
import '../../../auto_capture/presentation/views/auto_capture_settings_view.dart';
import '../../../backup/presentation/views/data_and_storage_view.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCurrencyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    final customDetails = ref.watch(customCurrencyProvider);
    final currencyNotifier = ref.read(selectedCurrencyProvider.notifier);
    final customNotifier = ref.read(customCurrencyProvider.notifier);

    // Effective display values — use custom details when 'Other' is active
    final badgeSymbol = selectedCurrency == AppCurrency.custom && customDetails != null
        ? customDetails.symbol
        : selectedCurrency.symbol;
    final badgeCode = selectedCurrency == AppCurrency.custom && customDetails != null
        ? customDetails.code
        : selectedCurrency.code;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Fynza',
              style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const _SectionHeader(label: 'Currency Setting'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isCurrencyExpanded = !_isCurrencyExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon, label, and current badge
                    Row(
                      children: [
                      Icon(
                        Icons.currency_exchange_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Currency',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$badgeSymbol  $badgeCode',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isCurrencyExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _isCurrencyExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                'Choose the currency used throughout the app',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Grid of currency chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                    children: AppCurrency.values.map((currency) {
                      final isSelected = currency == selectedCurrency;
                      final isCustom = currency == AppCurrency.custom;

                      String displaySymbol = currency.symbol;
                      String displayCode = currency.code;
                      IconData? overrideIcon;

                      if (isCustom) {
                        if (customDetails != null) {
                          displaySymbol = customDetails.symbol;
                          displayCode = customDetails.code;
                        } else {
                          displaySymbol = '?';
                          displayCode = 'OTHER';
                          overrideIcon = Icons.edit_rounded;
                        }
                      }

                      return _CurrencyChip(
                        symbol: displaySymbol,
                        code: displayCode,
                        icon: overrideIcon,
                        isSelected: isSelected,
                        onTap: () {
                          if (isCustom) {
                            _showCustomCurrencyDialog(
                              context,
                              currentDetails: customDetails,
                              onSave: (details) async {
                                await customNotifier.setDetails(details);
                                await currencyNotifier
                                    .setCurrency(AppCurrency.custom);
                                setState(() {
                                  _isCurrencyExpanded = false;
                                });
                              },
                              onDelete: () async {
                                await customNotifier.clearDetails();
                                await currencyNotifier
                                    .setCurrency(AppCurrency.usd);
                                setState(() {
                                  _isCurrencyExpanded = false;
                                });
                              },
                            );
                          } else {
                            currencyNotifier.setCurrency(currency);
                            setState(() {
                              _isCurrencyExpanded = false;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
          const _SectionHeader(label: 'Data & Storage'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.storage_rounded,
                  color: theme.colorScheme.primary),
              title: const Text('Data and storage'),
              subtitle: const Text('Backup, restore, and automatic backups'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DataAndStorageView(),
                  ),
                );
              },
            ),
          ),
          if (CaptureConstants.isEnabled) ...[
            const SizedBox(height: 16),
            const _SectionHeader(label: 'Automation'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.sms_outlined,
                    color: theme.colorScheme.primary),
                title: const Text('Auto-capture transactions'),
                subtitle: Text(
                  ref.watch(autoCaptureEnabledProvider)
                      ? 'Read bank SMS & payment notifications (On)'
                      : 'Turned off',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AutoCaptureSettingsView(),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          const _SectionHeader(label: 'About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.info_outline,
                  color: theme.colorScheme.primary),
              title: const Text('Fynza'),
              subtitle: const Text('Expense tracker — v1.0.0'),
            ),
          ),
          const SizedBox(height: 24),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
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

void _showCustomCurrencyDialog(
  BuildContext context, {
  required CustomCurrencyDetails? currentDetails,
  required Future<void> Function(CustomCurrencyDetails) onSave,
  required Future<void> Function() onDelete,
}) {
  final symbolCtrl = TextEditingController(text: currentDetails?.symbol ?? '');
  final codeCtrl = TextEditingController(text: currentDetails?.code ?? '');
  final nameCtrl = TextEditingController(text: currentDetails?.name ?? '');
  final formKey = GlobalKey<FormState>();

  showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.currency_exchange_rounded,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Custom Currency',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your preferred currency details',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: symbolCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Symbol',
                      hintText: 'e.g.  kr,  \u20ba,  \u0e3f',
                      prefixIcon: Icon(Icons.paid_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Currency Code',
                      hintText: 'e.g.  NOK,  TRY,  THB',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Currency Name',
                      hintText: 'e.g.  Norwegian Krone',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final details = CustomCurrencyDetails(
                          symbol: symbolCtrl.text.trim(),
                          code: codeCtrl.text.trim().toUpperCase(),
                          name: nameCtrl.text.trim(),
                        );
                        Navigator.of(ctx).pop();
                        await onSave(details);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Currency',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (currentDetails != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await onDelete();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Delete Custom Currency',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _CurrencyChip extends StatelessWidget {
  final String symbol;
  final String code;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyChip({
    required this.symbol,
    required this.code,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor =
        isSelected ? theme.colorScheme.primary : Colors.transparent;
    final fgColor = isSelected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, color: fgColor, size: 24)
              else
                Text(
                  symbol,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                code,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
