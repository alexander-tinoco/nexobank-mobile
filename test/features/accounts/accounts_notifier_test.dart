import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/accounts/data/account_repository_impl.dart';
import 'package:nexobank_mobile/features/accounts/domain/account_repository.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';
import 'package:nexobank_mobile/features/accounts/presentation/providers/accounts_notifier.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

final _fakeAccounts = [
  const Account(
    id: 'acc1',
    accountNumber: '0000111122223333',
    accountType: 'checking',
    balance: '1500.00',
    currency: 'MXN',
    status: 'active',
    ownerId: 'user1',
  ),
];

void main() {
  late MockAccountRepository mockRepo;

  setUp(() {
    mockRepo = MockAccountRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('AccountsNotifier', () {
    test('build loads accounts successfully', () async {
      when(() => mockRepo.getAccounts())
          .thenAnswer((_) async => Success(_fakeAccounts));

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(accountsNotifierProvider.future);
      expect(state, _fakeAccounts);
    });

    test('build emits AsyncError on network failure', () async {
      when(() => mockRepo.getAccounts())
          .thenAnswer((_) async => const Failure(NetworkError('sin conexión')));

      final container = makeContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(accountsNotifierProvider.future),
        throwsA(isA<NetworkError>()),
      );
    });

    test('refresh reloads accounts', () async {
      when(() => mockRepo.getAccounts())
          .thenAnswer((_) async => Success(_fakeAccounts));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(accountsNotifierProvider.future);
      await container.read(accountsNotifierProvider.notifier).refresh();

      verify(() => mockRepo.getAccounts()).called(2);
      final state = container.read(accountsNotifierProvider);
      expect(state.hasValue, isTrue);
    });
  });
}
