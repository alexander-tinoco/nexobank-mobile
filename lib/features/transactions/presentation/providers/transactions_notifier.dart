import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transactions/data/dtos/transaction_page_dto.dart';
import 'package:nexobank_mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:nexobank_mobile/features/transactions/domain/models/transaction.dart';
import 'package:nexobank_mobile/features/transactions/domain/transaction_repository.dart';

class TransactionsState {
  const TransactionsState({
    required this.transactions,
    required this.isLoading,
    required this.isLoadingMore,
    this.nextCursor,
    required this.hasMore,
    this.error,
  });

  final List<Transaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? nextCursor;
  final bool hasMore;
  final AppError? error;

  static const empty = TransactionsState(
    transactions: [],
    isLoading: false,
    isLoadingMore: false,
    hasMore: true,
  );

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    Object? nextCursor = _keep,
    bool? hasMore,
    AppError? error,
    bool clearError = false,
  }) =>
      TransactionsState(
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        nextCursor: nextCursor == _keep
            ? this.nextCursor
            : nextCursor as String?,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );

  static const _keep = Object();
}

class TransactionsNotifier extends Notifier<TransactionsState> {
  String? _currentAccountId;

  @override
  TransactionsState build() => TransactionsState.empty;

  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  Future<void> loadInitial(String accountId) async {
    _currentAccountId = accountId;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repo.getTransactions(accountId: accountId);
    state = switch (result) {
      Success<TransactionPageDto>(value: final page) => state.copyWith(
          transactions: page.transactions.map((d) => d.toDomain()).toList(),
          isLoading: false,
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      Failure<TransactionPageDto>(error: final e) => state.copyWith(
          isLoading: false,
          error: e,
        ),
    };
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || _currentAccountId == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    final result = await _repo.getTransactions(
      accountId: _currentAccountId!,
      cursor: state.nextCursor,
    );
    state = switch (result) {
      Success<TransactionPageDto>(value: final page) => state.copyWith(
          transactions: [
            ...state.transactions,
            ...page.transactions.map((d) => d.toDomain()),
          ],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      Failure<TransactionPageDto>(error: final e) => state.copyWith(
          isLoadingMore: false,
          error: e,
        ),
    };
  }
}

final transactionsNotifierProvider =
    NotifierProvider<TransactionsNotifier, TransactionsState>(
  TransactionsNotifier.new,
);
