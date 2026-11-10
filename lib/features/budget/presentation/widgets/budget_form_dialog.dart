import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/domain/models/category.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../shared/widgets/pressable_scale.dart';

class BudgetFormResult {
  final int categoryId;
  final int amountLimitCents;

  const BudgetFormResult({
    required this.categoryId,
    required this.amountLimitCents,
  });
}

class BudgetFormDialog extends ConsumerStatefulWidget {
  final List<Category> availableCategories;
  final int? initialCategoryId;
  final int? initialLimitCents;

  const BudgetFormDialog({
    super.key,
    required this.availableCategories,
    this.initialCategoryId,
    this.initialLimitCents,
  });

  @override
  ConsumerState<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends ConsumerState<BudgetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId =
        widget.initialCategoryId ??
        (widget.availableCategories.isNotEmpty
            ? widget.availableCategories.first.id
            : null);
    _amountController = TextEditingController(
      text: widget.initialLimitCents != null && widget.initialLimitCents! > 0
          ? CurrencyFormatter.centsToDecimalString(widget.initialLimitCents!)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(int unitIncrement) {
    final currentCents = CurrencyFormatter.parseToCents(_amountController.text);
    final newCents = currentCents + (unitIncrement * 100);
    _amountController.text = CurrencyFormatter.centsToDecimalString(newCents);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(selectedCurrencyProvider);
    final isEditing = widget.initialLimitCents != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: FadingScrollBoundary(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note
                          : Icons.account_balance_wallet_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    isEditing ? 'Edit Budget' : 'Set New Budget',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set a monthly spending limit',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Category Dropdown
                  if (widget.initialCategoryId == null) ...[
                    Text(
                      'Category',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: widget.availableCategories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Row(
                            children: [
                              CategoryIcon(
                                iconKey: cat.icon,
                                colorValue: cat.color,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cat.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Amount Field
                  Text(
                    'Monthly Limit',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      hintText: '0.00',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          currency.symbol,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a limit';
                      }
                      final cents = CurrencyFormatter.parseToCents(val);
                      if (cents <= 0) {
                        return 'Must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Quick increment chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _QuickDialogChip(
                          label: '+500',
                          onTap: () => _addAmount(500),
                        ),
                        const SizedBox(width: 8),
                        _QuickDialogChip(
                          label: '+1,000',
                          onTap: () => _addAmount(1000),
                        ),
                        const SizedBox(width: 8),
                        _QuickDialogChip(
                          label: '+2,000',
                          onTap: () => _addAmount(2000),
                        ),
                        const SizedBox(width: 8),
                        _QuickDialogChip(
                          label: '+5,000',
                          onTap: () => _addAmount(5000),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  PressableScale(
                    targetScale: 0.98,
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        HapticFeedback.mediumImpact();
                        final cents = CurrencyFormatter.parseToCents(
                          _amountController.text,
                        );
                        Navigator.of(context).pop(
                          BudgetFormResult(
                            categoryId: _selectedCategoryId!,
                            amountLimitCents: cents,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Save Budget',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickDialogChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDialogChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PressableScale(
      targetScale: 0.90,
      enableHaptics: false,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
