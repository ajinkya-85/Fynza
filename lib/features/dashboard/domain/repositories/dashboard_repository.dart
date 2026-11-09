import 'dart:async';
import '../../../../shared/models/category_spending.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class DashboardSummary {
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netBalanceCents;
  final List<TransactionWithCategory> recentTransactions;
  final List<CategorySpending> categorySpendings;

  const DashboardSummary({
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netBalanceCents,
    required this.recentTransactions,
    required this.categorySpendings,
  });

  const DashboardSummary.empty()
      : totalIncomeCents = 0,
        totalExpenseCents = 0,
        netBalanceCents = 0,
        recentTransactions = const [],
        categorySpendings = const [];
}

abstract class DashboardRepository {
  Stream<DashboardSummary> watchDashboardSummary({
    required int month,
    required int year,
  });
}

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
    StreamSubscription? incomeSub;
    StreamSubscription? expenseSub;
    StreamSubscription? recentSub;
    StreamSubscription? spendingSub;

    int currentIncome = 0;
    int currentExpense = 0;
    List<TransactionWithCategory> currentRecent = [];
    List<CategorySpending> currentSpendings = [];

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
            .listen((val) {
          currentIncome = val;
          emit();
        });

        expenseSub = _transactionRepository
            .watchTotal(
              type: TransactionType.expense,
              startDate: startDate,
              endDate: endDate,
            )
            .listen((val) {
          currentExpense = val;
          emit();
        });

        recentSub = _transactionRepository
            .watchRecentTransactions(limit: 5)
            .listen((val) {
          currentRecent = val;
          emit();
        });

        spendingSub = _transactionRepository
            .watchCategorySpending(startDate: startDate, endDate: endDate)
            .listen((val) {
          currentSpendings = val;
          emit();
        });
      },
      onCancel: () {
        incomeSub?.cancel();
        expenseSub?.cancel();
        recentSub?.cancel();
        spendingSub?.cancel();
      },
    );

    return controller.stream;
  }
}
