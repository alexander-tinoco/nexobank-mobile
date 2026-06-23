import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/accounts/data/account_repository_impl.dart';
import 'package:nexobank_mobile/features/accounts/domain/account_repository.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';
import 'package:nexobank_mobile/features/accounts/presentation/providers/account_detail_notifier.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

const _fakeAccount = Account(
  id: 'acc1',
  accountNumber: '0000111122223333',
  accountType: 'checking',
  balance: '1500.00',
  currency: 'MXN',
  status: 'active',
  ownerId: 'user1',
);

void main() {
  late MockAccountRepository mockRepo;

  setUp(() {
    mockRepo = MockAccountRepository();
  });

  ProviderContainer makeContainer({String currentUserId = 'user1'}) {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepo),
        currentUserIdProvider.overrideWithValue(currentUserId),
      ],
    );
  }

  group('AccountDetailNotifier', () {
    test('loads account when ownerId matches current user', () async {
      when(() => mockRepo.getAccountById('acc1'))
          .thenAnswer((_) async => const Success(_fakeAccount));

      final container = makeContainer(currentUserId: 'user1');
      addTearDown(container.dispose);

      final account =
          await container.read(accountDetailNotifierProvider('acc1').future);
      expect(account.id, 'acc1');
      expect(account.balance, '1500.00');
    });

    test('throws when ownerId does not match current user', () async {
      when(() => mockRepo.getAccountById('acc1'))
          .thenAnswer((_) async => const Success(_fakeAccount));

      final container = makeContainer(currentUserId: 'other_user');
      addTearDown(container.dispose);

      await expectLater(
        container.read(accountDetailNotifierProvider('acc1').future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
