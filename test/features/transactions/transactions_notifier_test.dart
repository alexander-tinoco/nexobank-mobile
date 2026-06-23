import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transactions/data/dtos/transaction_dto.dart';
import 'package:nexobank_mobile/features/transactions/data/dtos/transaction_page_dto.dart';
import 'package:nexobank_mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:nexobank_mobile/features/transactions/domain/transaction_repository.dart';
import 'package:nexobank_mobile/features/transactions/presentation/providers/transactions_notifier.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

TransactionDto _makeDto(String id) => TransactionDto(
      id: id,
      type: 'credit',
      amount: '100.00',
      description: 'Test $id',
      status: 'completed',
      createdAt: '2026-06-23T10:00:00Z',
      balanceAfter: '1000.00',
    );

List<TransactionDto> _makeDtos(int count, {int offset = 0}) =>
    List.generate(count, (i) => _makeDto('txn-${i + offset}'));

void main() {
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('TransactionsNotifier', () {
    test('initial state is empty', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final state = container.read(transactionsNotifierProvider);
      expect(state.transactions, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
    });

    test('loadInitial: loads first page, hasMore=true', () async {
      when(
        () => mockRepo.getTransactions(
          accountId: 'acc-1',
          cursor: null,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => Success(
          TransactionPageDto(
            transactions: _makeDtos(20),
            nextCursor: 'cursor-2',
            hasMore: true,
          ),
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(transactionsNotifierProvider.notifier)
          .loadInitial('acc-1');

      final state = container.read(transactionsNotifierProvider);
      expect(state.transactions.length, 20);
      expect(state.hasMore, isTrue);
      expect(state.nextCursor, 'cursor-2');
      expect(state.isLoading, isFalse);
    });

    test('loadMore: accumulates second page, hasMore=false at end', () async {
      when(
        () => mockRepo.getTransactions(
          accountId: 'acc-1',
          cursor: null,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => Success(
          TransactionPageDto(
            transactions: _makeDtos(20),
            nextCursor: 'cursor-2',
            hasMore: true,
          ),
        ),
      );
      when(
        () => mockRepo.getTransactions(
          accountId: 'acc-1',
          cursor: 'cursor-2',
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => Success(
          TransactionPageDto(
            transactions: _makeDtos(5, offset: 20),
            nextCursor: null,
            hasMore: false,
          ),
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(transactionsNotifierProvider.notifier)
          .loadInitial('acc-1');
      await container
          .read(transactionsNotifierProvider.notifier)
          .loadMore();

      final state = container.read(transactionsNotifierProvider);
      expect(state.transactions.length, 25);
      expect(state.hasMore, isFalse);
      expect(state.nextCursor, isNull);
    });

    test('loadMore when hasMore=false does not call repo again', () async {
      when(
        () => mockRepo.getTransactions(
          accountId: 'acc-1',
          cursor: null,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => Success(
          TransactionPageDto(
            transactions: _makeDtos(5),
            nextCursor: null,
            hasMore: false,
          ),
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(transactionsNotifierProvider.notifier)
          .loadInitial('acc-1');
      await container
          .read(transactionsNotifierProvider.notifier)
          .loadMore(); // should be a no-op

      verify(
        () => mockRepo.getTransactions(
          accountId: any(named: 'accountId'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).called(1); // only the initial load
    });
  });
}
