import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_request_dto.dart';
import 'package:nexobank_mobile/features/transfers/data/transfer_repository_impl.dart';
import 'package:nexobank_mobile/features/transfers/domain/models/transfer.dart';
import 'package:nexobank_mobile/features/transfers/domain/transfer_repository.dart';
import 'package:nexobank_mobile/features/transfers/presentation/providers/transfer_notifier.dart';

class MockTransferRepository extends Mock implements TransferRepository {}

const _fakeTransfer = Transfer(
  id: 'txn-1',
  amount: '500.00',
  status: 'completed',
  originAccountId: 'acc-origin',
  destinationAccountId: 'acc-dest',
  createdAt: '2026-06-23T10:00:00Z',
);

const _dto = TransferRequestDto(
  amount: '500.00',
  destinationAccountId: 'acc-dest',
  idempotencyKey: 'key-123',
);

void main() {
  late MockTransferRepository mockRepo;

  setUp(() {
    mockRepo = MockTransferRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        transferRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('TransferNotifier', () {
    test('initial state is TransferIdle', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(container.read(transferNotifierProvider), isA<TransferIdle>());
    });

    test('happy path: execute() → TransferSuccess', () async {
      when(() => mockRepo.executeTransfer(_dto))
          .thenAnswer((_) async => const Success(_fakeTransfer));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(transferNotifierProvider.notifier)
          .execute(_dto);

      final state = container.read(transferNotifierProvider);
      expect(state, isA<TransferSuccess>());
      expect((state as TransferSuccess).transfer.id, 'txn-1');
    });

    test('INSUFFICIENT_FUNDS: execute() → TransferFailure with InsufficientFundsError',
        () async {
      when(() => mockRepo.executeTransfer(_dto))
          .thenAnswer((_) async => const Failure(InsufficientFundsError()));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(transferNotifierProvider.notifier)
          .execute(_dto);

      final state = container.read(transferNotifierProvider);
      expect(state, isA<TransferFailure>());
      expect(
        (state as TransferFailure).error,
        isA<InsufficientFundsError>(),
      );
    });

    test('double submit is blocked while loading', () async {
      // Simulate a slow response
      when(() => mockRepo.executeTransfer(_dto)).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 100), () {
          return const Success(_fakeTransfer);
        }),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      // Fire two concurrent executes
      final first = container
          .read(transferNotifierProvider.notifier)
          .execute(_dto);
      final second = container
          .read(transferNotifierProvider.notifier)
          .execute(_dto);

      await Future.wait([first, second]);

      // Repository should only have been called once
      verify(() => mockRepo.executeTransfer(_dto)).called(1);
    });

    test('reset() returns to TransferIdle', () async {
      when(() => mockRepo.executeTransfer(_dto))
          .thenAnswer((_) async => const Success(_fakeTransfer));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(transferNotifierProvider.notifier)
          .execute(_dto);
      container.read(transferNotifierProvider.notifier).reset();

      expect(container.read(transferNotifierProvider), isA<TransferIdle>());
    });
  });
}
