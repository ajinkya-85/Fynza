import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/capture_constants.dart';
import '../../../auto_capture/data/services/auto_capture_scheduler.dart';
import '../../../auto_capture/data/services/capture_preferences_service.dart';
import '../../../backup/data/services/auto_backup_scheduler.dart';
import '../../../backup/domain/repositories/backup_repository.dart';
import '../../../budget/presentation/views/budget_screen.dart';
import '../../../categories/presentation/views/categories_screen.dart';
import '../../../dashboard/presentation/views/dashboard_screen.dart';
import '../../../settings/presentation/views/settings_screen.dart';
import '../../../transactions/presentation/views/transactions_screen.dart';
import '../../../transactions/presentation/views/transaction_form_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoBackupSchedulerProvider).runLaunchCatchUp(
            ref.read(backupRepositoryProvider),
          );
      if (CaptureConstants.isEnabled && ref.read(autoCaptureEnabledProvider)) {
        ref.read(autoCaptureSchedulerProvider).drainNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToTransactions: () => setState(() => _selectedIndex = 1),
      ),
      const TransactionsScreen(),
      const BudgetScreen(),
      const CategoriesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'main_fab',
        tooltip: 'Add transaction',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TransactionFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
