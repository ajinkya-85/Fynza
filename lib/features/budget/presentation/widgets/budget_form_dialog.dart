import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/spring_curves.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/domain/models/category.dart';
import '../../../transactions/presentation/view_models/transaction_form_notifier.dart';
import '../../../../shared/models/transaction_type.dart';
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
  late final TextEditingController _categorySearchController;
  int? _selectedCategoryId;
  bool _isCategoryListExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _amountController = TextEditingController(
      text: widget.initialLimitCents != null && widget.initialLimitCents! > 0
          ? CurrencyFormatter.centsToDecimalString(widget.initialLimitCents!)
          : '',
    );
    _categorySearchController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  void _addAmount(int unitIncrement) {
    final currentCents = CurrencyFormatter.parseToCents(_amountController.text);
    final newCents = currentCents + (unitIncrement * 100);
    _amountController.text = CurrencyFormatter.centsToDecimalString(newCents);
  }

  void _selectCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _isCategoryListExpanded = false;
      _categorySearchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(selectedCurrencyProvider);
    final isEditing = widget.initialLimitCents != null;
    final recentCategoriesProvider = recentTransactionCategoriesProvider(
      TransactionType.expense,
    );
    final recentCategoryIds =
        ref.watch(recentCategoriesProvider).valueOrNull ?? const <int>[];
    final categories = widget.availableCategories;
    final recentCategories = <Category>[];
    for (final id in recentCategoryIds) {
      for (final category in categories) {
        if (category.id == id) {
          recentCategories.add(category);
          break;
        }
      }
    }
    final selectedCategories = categories
        .where((category) => category.id == _selectedCategoryId)
        .toList();
    final selectedCategory = selectedCategories.isEmpty
        ? null
        : selectedCategories.first;
    final orderedRecent = [
      ?selectedCategory,
      ...recentCategories.where(
        (category) => category.id != _selectedCategoryId,
      ),
    ];
    final visibleRecent =
        (orderedRecent.isNotEmpty ? orderedRecent : categories)
            .take(3)
            .toList();
    final visibleRecentIds = visibleRecent
        .map((category) => category.id)
        .toSet();
    final query = _categorySearchController.text.trim().toLowerCase();
    final moreCategories = categories.where((category) {
      if (query.isNotEmpty) {
        return category.name.toLowerCase().contains(query);
      }
      return !visibleRecentIds.contains(category.id);
    }).toList();

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

                  // Category Picker
                  if (widget.initialCategoryId == null) ...[
                    Text(
                      'Category',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (visibleRecent.isNotEmpty) ...[
                      Text(
                        recentCategories.isEmpty ? 'Categories' : 'Recent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: visibleRecent.map((category) {
                          return _BudgetCategoryChip(
                            category: category,
                            isSelected: _selectedCategoryId == category.id,
                            onPressed: () => _selectCategory(category.id),
                          );
                        }).toList(),
                      ),
                      if (categories.length > visibleRecent.length)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isCategoryListExpanded =
                                    !_isCategoryListExpanded;
                                if (!_isCategoryListExpanded) {
                                  _categorySearchController.clear();
                                }
                              });
                            },
                            icon: AnimatedRotation(
                              turns: _isCategoryListExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: SpringCurves.criticallyDamped,
                              child: const Icon(Icons.expand_more_rounded),
                            ),
                            label: Text(
                              _isCategoryListExpanded
                                  ? 'Less'
                                  : 'More (${categories.length - visibleRecent.length})',
                            ),
                          ),
                        ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: SpringCurves.criticallyDamped,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            reverseDuration: const Duration(milliseconds: 140),
                            switchInCurve: SpringCurves.criticallyDamped,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -0.025),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: _isCategoryListExpanded
                                ? Column(
                                    key: const ValueKey(
                                      'expanded_budget_categories',
                                    ),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        key: const Key(
                                          'budget_category_search_field',
                                        ),
                                        controller: _categorySearchController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          hintText: 'Search categories',
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                          ),
                                          suffixIcon: query.isEmpty
                                              ? null
                                              : IconButton(
                                                  tooltip: 'Clear search',
                                                  onPressed: () {
                                                    _categorySearchController
                                                        .clear();
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                  ),
                                                ),
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (moreCategories.isEmpty)
                                        Text(
                                          'No matching categories.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        )
                                      else
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: moreCategories.map((
                                            category,
                                          ) {
                                            final isSelected =
                                                _selectedCategoryId ==
                                                category.id;
                                            return _BudgetCategoryChip(
                                              category: category,
                                              isSelected: isSelected,
                                              onPressed: () =>
                                                  _selectCategory(category.id),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  )
                                : const SizedBox(
                                    key: ValueKey(
                                      'collapsed_budget_categories',
                                    ),
                                    width: double.infinity,
                                  ),
                          ),
                        ),
                      ),
                    ],
                    FormField<int>(
                      validator: (_) => _selectedCategoryId == null
                          ? 'Please select a category'
                          : null,
                      builder: (field) => field.hasError
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                field.errorText!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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

class _BudgetCategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onPressed;

  const _BudgetCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(category.color);

    return PressableScale(
      targetScale: 0.96,
      enableHaptics: false,
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: SpringCurves.criticallyDamped,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? categoryColor.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? categoryColor
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryIcon(
              iconKey: category.icon,
              colorValue: category.color,
              size: 20,
            ),
            const SizedBox(width: 7),
            Text(
              category.name,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? categoryColor
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_circle_rounded, size: 16, color: categoryColor),
            ],
          ],
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
