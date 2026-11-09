import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/fluid_segmented_control.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../view_models/categories_notifier.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  bool _isIncome = false;

  Future<void> _showAddCategoryDialog(bool isIncome) async {
    final result = await Navigator.of(context).push<CategoryFormData>(
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(initialIsIncome: isIncome),
      ),
    );

    if (result != null && mounted) {
      await ref.read(categoriesNotifierProvider.notifier).addCategory(
            name: result.name,
            icon: result.icon,
            color: result.color,
            isIncome: result.isIncome,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesState = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: theme.colorScheme.primary,
            ),
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Apple-style Fluid Segmented Control
          FluidSegmentedControl<bool>(
            items: const [false, true],
            selectedItem: _isIncome,
            onSelectedItemChanged: (val) {
              setState(() {
                _isIncome = val;
              });
            },
            labelBuilder: (isInc) => isInc ? 'Income' : 'Expenses',
            iconBuilder: (isInc) => isInc
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
          ),
          const SizedBox(height: 8),

          // Categories List
          Expanded(
            child: categoriesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (categories) {
                final filtered = categories
                    .where((c) => c.isIncome == _isIncome)
                    .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.category_outlined,
                    title: 'No Categories Found',
                    subtitle: _isIncome
                        ? 'Add income categories like Salary, Freelance, etc.'
                        : 'Add expense categories like Groceries, Rent, etc.',
                    action: FilledButton.tonalIcon(
                      onPressed: () => _showAddCategoryDialog(_isIncome),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    final catColor = Color(category.color);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35)
                            : theme.colorScheme.surfaceContainerHigh
                                .withValues(alpha: 0.45),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: CategoryIcon(
                              iconKey: category.icon,
                              colorValue: category.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              category.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          PressableScale(
                            targetScale: 0.88,
                            enableHaptics: false,
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category?'),
                                  content: Text(
                                    'Are you sure you want to delete "${category.name}"? '
                                    'Associated transactions will also be deleted.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                HapticFeedback.mediumImpact();
                                await ref
                                    .read(categoriesNotifierProvider.notifier)
                                    .deleteCategory(category.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: () => _showAddCategoryDialog(_isIncome),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}
