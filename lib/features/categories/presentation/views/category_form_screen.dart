import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/fluid_segmented_control.dart';
import '../../../../shared/widgets/pressable_scale.dart';

class CategoryFormData {
  final String name;
  final String icon;
  final int color;
  final bool isIncome;

  const CategoryFormData({
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });
}

class CategoryFormScreen extends StatefulWidget {
  final bool initialIsIncome;

  const CategoryFormScreen({super.key, this.initialIsIncome = false});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedIcon = CategoryIcon.availableIcons.first.key;
    _selectedColor = CategoryIcon.availableColors.first;
    _isIncome = widget.initialIsIncome;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(
        CategoryFormData(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          isIncome: _isIncome,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              'New Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Save Category',
            icon: const Icon(Icons.check_rounded),
            onPressed: _submit,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fluid Segmented Type Control
              FluidSegmentedControl<bool>(
                padding: EdgeInsets.zero,
                items: const [false, true],
                selectedItem: _isIncome,
                onSelectedItemChanged: (val) {
                  setState(() {
                    _isIncome = val;
                  });
                },
                labelBuilder: (isInc) => isInc ? 'Income' : 'Expense',
                iconBuilder: (isInc) => isInc
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
              ),
              const SizedBox(height: 24),

              // Category Name Input
              Text(
                'Category Name',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 8),
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
                child: TextFormField(
                  controller: _nameController,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    letterSpacing: -0.1,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'e.g. Subscriptions, Groceries...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    icon: Icon(
                      Icons.label_outline_rounded,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Icon Picker Section
              Text(
                'Select Icon',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: CategoryIcon.availableIcons.map((item) {
                  final isSelected = item.key == _selectedIcon;
                  return PressableScale(
                    targetScale: 0.88,
                    enableHaptics: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = item.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : (isDark
                                  ? theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.4)
                                  : theme.colorScheme.surfaceContainerHigh
                                        .withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04)),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        item.value,
                        size: 22,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Color Picker Section
              Text(
                'Select Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: CategoryIcon.availableColors.map((colorValue) {
                  final isSelected = colorValue == _selectedColor;
                  final color = Color(colorValue);

                  return PressableScale(
                    targetScale: 0.85,
                    enableHaptics: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = colorValue);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.surface,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: color.computeLuminance() > 0.42
                                  ? theme.colorScheme.onSurface
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Save Category Button
              PressableScale(
                targetScale: 0.98,
                onPressed: _submit,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save Category',
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
