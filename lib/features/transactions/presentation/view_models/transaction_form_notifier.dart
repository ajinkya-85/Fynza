import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/database_provider.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../../auto_capture/domain/repositories/capture_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionFormState {
  final int? editingId;
  final int amountCents;
  final TransactionType type;
  final int? categoryId;
  final DateTime date;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const TransactionFormState({
    this.editingId,
    required this.amountCents,
    required this.type,
    this.categoryId,
    required this.date,
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  factory TransactionFormState.initial({
    TransactionWithCategory? initial,
    int? prefilledAmountCents,
    TransactionType? prefilledType,
    int? prefilledCategoryId,
    DateTime? prefilledDate,
    String? prefilledNote,
  }) {
    if (initial != null) {
      return TransactionFormState(
        editingId: initial.transaction.id,
        amountCents: initial.transaction.amount,
        type: initial.transaction.type,
        categoryId: initial.transaction.categoryId,
        date: initial.transaction.date,
        note: initial.transaction.note ?? '',
      );
    }
    return TransactionFormState(
      amountCents: prefilledAmountCents ?? 0,
      type: prefilledType ?? TransactionType.expense,
      categoryId: prefilledCategoryId,
      date: prefilledDate ?? DateTime.now(),
      note: prefilledNote ?? '',
    );
  }

  bool get isEditing => editingId != null;

  TransactionFormState copyWith({
    int? editingId,
    int? amountCents,
    TransactionType? type,
    int? categoryId,
    bool clearCategory = false,
    DateTime? date,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return TransactionFormState(
      editingId: editingId ?? this.editingId,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      date: date ?? this.date,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TransactionFormNotifier extends StateNotifier<TransactionFormState> {
  final TransactionRepository _repository;
  final CaptureRepository? _captureRepo;

  TransactionFormNotifier(
    this._repository, [
    TransactionWithCategory? initial,
    this._captureRepo,
  ]) : super(TransactionFormState.initial(initial: initial));

  void setAmount(int cents) {
    state = state.copyWith(amountCents: cents, clearError: true);
  }

  void setType(TransactionType type) {
    state = state.copyWith(
      type: type,
      clearCategory: type != state.type,
      clearError: true,
    );
  }

  void setCategory(int categoryId) {
    state = state.copyWith(categoryId: categoryId, clearError: true);
  }

  void clearCategory() {
    state = state.copyWith(clearCategory: true, clearError: true);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, clearError: true);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  Future<bool> save({int? captureIdToConfirm}) async {
    if (state.amountCents <= 0) {
      state = state.copyWith(
        errorMessage: 'Please enter an amount greater than 0',
      );
      return false;
    }
    if (state.categoryId == null) {
      state = state.copyWith(errorMessage: 'Please select a category');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      if (captureIdToConfirm != null && _captureRepo != null) {
        await _captureRepo.confirmCapture(
          captureIdToConfirm,
          categoryId: state.categoryId!,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
          date: state.date,
          amountCents: state.amountCents,
          type: state.type,
        );
      } else if (state.isEditing) {
        await _repository.updateTransaction(
          id: state.editingId!,
          amountCents: state.amountCents,
          type: state.type,
          categoryId: state.categoryId!,
          date: state.date,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
        );
      } else {
        await _repository.addTransaction(
          amountCents: state.amountCents,
          type: state.type,
          categoryId: state.categoryId!,
          date: state.date,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
        );
      }

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save transaction: $e',
      );
      return false;
    }
  }
}

final transactionFormNotifierProvider = StateNotifierProvider.autoDispose
    .family<
      TransactionFormNotifier,
      TransactionFormState,
      TransactionWithCategory?
    >((ref, initial) {
      final repository = ref.watch(transactionRepositoryProvider);
      final captureRepo = ref.watch(captureRepositoryProvider);
      return TransactionFormNotifier(repository, initial, captureRepo);
    });

final recentTransactionCategoriesProvider = StreamProvider.autoDispose
    .family<List<int>, TransactionType>((ref, type) {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.watchRecentTransactions(limit: 100).map((transactions) {
        final categoryIds = <int>[];
        for (final item in transactions) {
          if (item.transaction.type == type &&
              !categoryIds.contains(item.transaction.categoryId)) {
            categoryIds.add(item.transaction.categoryId);
          }
          if (categoryIds.length == 3) break;
        }
        return categoryIds;
      });
    });
