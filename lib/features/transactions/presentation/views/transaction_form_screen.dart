import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/spring_curves.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../shared/widgets/fluid_segmented_control.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/presentation/view_models/categories_notifier.dart';
import '../view_models/transaction_form_notifier.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionWithCategory? initial;
  final int? captureIdToConfirm;
  final int? prefilledAmountCents;
  final TransactionType? prefilledType;
  final int? prefilledCategoryId;
  final DateTime? prefilledDate;
  final String? prefilledNote;

  const TransactionFormScreen({
    super.key,
    this.initial,
    this.captureIdToConfirm,
    this.prefilledAmountCents,
    this.prefilledType,
    this.prefilledCategoryId,
    this.prefilledDate,
    this.prefilledNote,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _categorySearchController;
  bool _isCategoryListExpanded = false;

  @override
  void initState() {
    super.initState();
    final initialCents =
        widget.initial?.transaction.amount ?? widget.prefilledAmountCents ?? 0;
    _amountController = TextEditingController(
      text: initialCents > 0
          ? CurrencyFormatter.centsToDecimalString(initialCents)
          : '',
    );
    _noteController = TextEditingController(
      text: widget.initial?.transaction.note ?? widget.prefilledNote ?? '',
    );
    _categorySearchController = TextEditingController();

    if (widget.initial == null &&
        (widget.prefilledAmountCents != null ||
            widget.prefilledType != null ||
            widget.prefilledCategoryId != null ||
            widget.prefilledDate != null ||
            widget.prefilledNote != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(
          transactionFormNotifierProvider(widget.initial).notifier,
        );
        if (widget.prefilledAmountCents != null) {
          notifier.setAmount(widget.prefilledAmountCents!);
        }
        if (widget.prefilledType != null) {
          notifier.setType(widget.prefilledType!);
        }
        if (widget.prefilledCategoryId != null) {
          notifier.setCategory(widget.prefilledCategoryId!);
        }
        if (widget.prefilledDate != null) {
          notifier.setDate(widget.prefilledDate!);
        }
        if (widget.prefilledNote != null) {
          notifier.setNote(widget.prefilledNote!);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final cents = CurrencyFormatter.parseToCents(val);
    ref
        .read(transactionFormNotifierProvider(widget.initial).notifier)
        .setAmount(cents);
  }

  void _addAmount(int unitIncrement) {
    final currentCents = CurrencyFormatter.parseToCents(_amountController.text);
    final newCents = currentCents + (unitIncrement * 100);
    _amountController.text = CurrencyFormatter.centsToDecimalString(newCents);
    _onAmountChanged(_amountController.text);
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref
          .read(transactionFormNotifierProvider(widget.initial).notifier)
          .setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formState = ref.watch(
      transactionFormNotifierProvider(widget.initial),
    );
    final formNotifier = ref.read(
      transactionFormNotifierProvider(widget.initial).notifier,
    );
    final categoriesState = ref.watch(categoriesNotifierProvider);
    final recentCategoryIdsAsync = ref.watch(
      recentTransactionCategoriesProvider(formState.type),
    );
    final currency = ref.watch(selectedCurrencyProvider);

    final isIncome = formState.type == TransactionType.income;
    final amountColor = isIncome
        ? const Color(0xFF2E7A7D)
        : theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fynza',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              formState.isEditing ? 'Edit Transaction' : 'New Transaction',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: FadingScrollBoundary(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fluid Segmented Type Control: Expense / Income
              FluidSegmentedControl<TransactionType>(
                padding: EdgeInsets.zero,
                items: const [TransactionType.expense, TransactionType.income],
                selectedItem: formState.type,
                onSelectedItemChanged: (type) => formNotifier.setType(type),
                labelBuilder: (type) => type.isExpense ? 'Expense' : 'Income',
                iconBuilder: (type) => type.isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 20),

              // Hero Optical Amount Display Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        )
                      : theme.colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _amountController,
                          builder: (context, value, _) {
                            if (value.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return PressableScale(
                              targetScale: 0.85,
                              enableHaptics: false,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _amountController.clear();
                                _onAmountChanged('');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.cancel_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                        letterSpacing: -1.0,
                      ),
                      cursorRadius: const Radius.circular(2),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currency.symbol,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: amountColor.withValues(alpha: 0.7),
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        hintText: '0.00',
                        hintStyle: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                          letterSpacing: -1.0,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: _onAmountChanged,
                    ),
                    const SizedBox(height: 16),
                    // Quick increment chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _QuickAmountChip(
                            label: '+50',
                            onTap: () => _addAmount(50),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+100',
                            onTap: () => _addAmount(100),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+500',
                            onTap: () => _addAmount(500),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+1,000',
                            onTap: () => _addAmount(1000),
                          ),
                          const SizedBox(width: 8),
                          _QuickAmountChip(
                            label: '+5,000',
                            onTap: () => _addAmount(5000),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Picker
              Text(
                'Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
              categoriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading categories: $err'),
                data: (categories) {
                  final filtered = categories
                      .where(
                        (c) =>
                            c.isIncome ==
                            (formState.type == TransactionType.income),
                      )
                      .toList();

                  if (filtered.isEmpty) {
                    return Text(
                      'No categories available for this type.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }

                  final recentIds = recentCategoryIdsAsync.valueOrNull ?? [];
                  final recentCategories = <Category>[];
                  for (final id in recentIds) {
                    for (final category in filtered) {
                      if (category.id == id) {
                        recentCategories.add(category);
                        break;
                      }
                    }
                  }
                  final selectedCategories = filtered
                      .where((category) => category.id == formState.categoryId)
                      .toList();
                  final selectedCategory = selectedCategories.isEmpty
                      ? null
                      : selectedCategories.first;
                  final orderedRecent = [
                    ?selectedCategory,
                    ...recentCategories.where(
                      (category) => category.id != formState.categoryId,
                    ),
                  ];
                  final visibleRecent =
                      (orderedRecent.isNotEmpty ? orderedRecent : filtered)
                          .take(3)
                          .toList();
                  final visibleRecentIds = visibleRecent
                      .map((category) => category.id)
                      .toSet();
                  final query = _categorySearchController.text
                      .trim()
                      .toLowerCase();
                  final moreCategories = filtered.where((category) {
                    if (query.isNotEmpty) {
                      return category.name.toLowerCase().contains(query);
                    }
                    return !visibleRecentIds.contains(category.id);
                  }).toList();

                  Widget categoryChips(List<Category> items) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: items.map((cat) {
                      final isSelected = formState.categoryId == cat.id;
                      return _CategoryChip(
                        label: cat.name,
                        iconKey: cat.icon,
                        colorValue: cat.color,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _isCategoryListExpanded = false;
                            _categorySearchController.clear();
                          });
                          formNotifier.setCategory(cat.id);
                        },
                      );
                    }).toList(),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recentCategories.isEmpty ? 'Categories' : 'Recent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      categoryChips(visibleRecent),
                      if (filtered.length > visibleRecent.length) ...[
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
                                  : 'More (${filtered.length - visibleRecent.length})',
                            ),
                          ),
                        ),
                      ],
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
                                    key: const ValueKey('expanded_categories'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        key: const Key('category_search_field'),
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
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        switchInCurve:
                                            SpringCurves.criticallyDamped,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                        child: moreCategories.isEmpty
                                            ? Text(
                                                'No matching categories.',
                                                key: const ValueKey(
                                                  'no_matching_categories',
                                                ),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              )
                                            : KeyedSubtree(
                                                key: ValueKey(query),
                                                child: categoryChips(
                                                  moreCategories,
                                                ),
                                              ),
                                      ),
                                    ],
                                  )
                                : const SizedBox(
                                    key: ValueKey('collapsed_categories'),
                                    width: double.infinity,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Date Picker Card
              PressableScale(
                targetScale: 0.98,
                onPressed: () => _pickDate(context, formState.date),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          )
                        : theme.colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.45,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.fullDate(formState.date),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Note Input
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        )
                      : theme.colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.45,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: TextField(
                  controller: _noteController,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    letterSpacing: -0.1,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Note (Optional, e.g. Lunch with team)',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    icon: Icon(
                      Icons.edit_note_rounded,
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onChanged: formNotifier.setNote,
                ),
              ),
              const SizedBox(height: 24),

              // Error message if any
              if (formState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formState.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Primary Submit Button with zero-latency PressableScale
              PressableScale(
                targetScale: 0.98,
                onPressed: formState.isSubmitting
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        final navigator = Navigator.of(context);
                        final selectedCategoryMatchesType =
                            categoriesState.valueOrNull?.any(
                              (category) =>
                                  category.id == formState.categoryId &&
                                  category.isIncome == isIncome,
                            ) ??
                            false;
                        if (!selectedCategoryMatchesType) {
                          formNotifier.clearCategory();
                        }
                        final success = await formNotifier.save(
                          captureIdToConfirm: widget.captureIdToConfirm,
                        );
                        if (success && mounted) {
                          HapticFeedback.mediumImpact();
                          navigator.pop(true);
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: formState.isSubmitting
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              formState.isEditing
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formState.isEditing
                                  ? 'Save Changes'
                                  : 'Add Transaction',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tactile quick amount addition chip with spring bounce.
class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

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

/// Custom tactile category chip with spring scaling, glowing dynamic border,
/// and instant haptic selection.
class _CategoryChip extends StatelessWidget {
  final String label;
  final String iconKey;
  final int colorValue;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.iconKey,
    required this.colorValue,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = Color(colorValue);

    final bgColor = isSelected
        ? catColor.withValues(alpha: isDark ? 0.25 : 0.15)
        : (isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5));

    final borderColor = isSelected
        ? catColor
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06));

    final textColor = isSelected
        ? (isDark ? Colors.white : catColor)
        : theme.colorScheme.onSurfaceVariant;

    return PressableScale(
      targetScale: 0.94,
      enableHaptics: false,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: SpringCurves.criticallyDamped,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: catColor.withValues(alpha: isDark ? 0.35 : 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: isSelected ? 0.35 : 0.15),
                shape: BoxShape.circle,
              ),
              child: CategoryIcon(
                iconKey: iconKey,
                colorValue: colorValue,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
