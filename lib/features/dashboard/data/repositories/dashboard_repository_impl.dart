import 'dart:async';

import '../../../../shared/models/category_spending.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final TransactionRepository _transactionRepository;

  DashboardRepositoryImpl(this._transactionRepository);

  @override
  Stream<DashboardSummary> watchDashboardSummary({
    required int month,
    required int year,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    late StreamController<DashboardSummary> controller;
    StreamSubscription<int>? incomeSub;
    StreamSubscription<int>? expenseSub;
    StreamSubscription<List<TransactionWithCategory>>? recentSub;
    StreamSubscription<List<CategorySpending>>? spendingSub;

    int currentIncome = 0;
    int currentExpense = 0;
    List<TransactionWithCategory> currentRecent = [];
    var currentSpendings = <CategorySpending>[];

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          DashboardSummary(
            totalIncomeCents: currentIncome,
            totalExpenseCents: currentExpense,
            netBalanceCents: currentIncome - currentExpense,
            recentTransactions: currentRecent,
            categorySpendings: currentSpendings,
          ),
        );
      }
    }

    controller = StreamController<DashboardSummary>(
      onListen: () {
        incomeSub = _transactionRepository
            .watchTotal(
              type: TransactionType.income,
              startDate: startDate,
              endDate: endDate,
            )
            .listen((value) {
              currentIncome = value;
              emit();
            });

        expenseSub = _transactionRepository
            .watchTotal(
              type: TransactionType.expense,
              startDate: startDate,
              endDate: endDate,
            )
            .listen((value) {
              currentExpense = value;
              emit();
            });

        recentSub = _transactionRepository
            .watchRecentTransactions(limit: 5)
            .listen((value) {
              currentRecent = value;
              emit();
            });

        spendingSub = _transactionRepository
            .watchCategorySpending(startDate: startDate, endDate: endDate)
            .listen((value) {
              currentSpendings = value;
              emit();
            });
      },
      onCancel: () async {
        await incomeSub?.cancel();
        await expenseSub?.cancel();
        await recentSub?.cancel();
        await spendingSub?.cancel();
      },
    );

    return controller.stream;
  }
}
