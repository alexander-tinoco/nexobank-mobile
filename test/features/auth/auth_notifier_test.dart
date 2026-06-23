import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexobank_mobile/features/auth/domain/auth_repository.dart';
import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';
import 'package:nexobank_mobile/features/auth/presentation/providers/auth_notifier.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorage extends Mock implements SecureStorage {}

class MockRouterAuthNotifier extends Mock implements RouterAuthNotifier {
  @override
  void onAuthStateChanged() {}
}

const _testUser = AuthUser(id: '1', name: 'Test User', email: 'test@test.com');

void main() {
  late MockAuthRepository mockRepo;
  late MockSecureStorage mockStorage;
  late MockRouterAuthNotifier mockRouterNotifier;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockSecureStorage();
    mockRouterNotifier = MockRouterAuthNotifier();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        secureStorageProvider.overrideWithValue(mockStorage),
        routerAuthNotifierProvider.overrideWithValue(mockRouterNotifier),
      ],
    );
  }

  group('AuthNotifier', () {
    test('build: sin token devuelve null', () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);
      expect(state, isNull);
    });

    test('build: con token y userData restaura la sesión', () async {
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'valid_token');
      when(() => mockStorage.readUserData())
          .thenAnswer((_) async => _testUser.toJsonString());

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);
      expect(state?.id, '1');
      expect(state?.email, 'test@test.com');
    });

    test('build: token presente pero userData null devuelve null', () async {
      when(() => mockStorage.readAccessToken())
          .thenAnswer((_) async => 'valid_token');
      when(() => mockStorage.readUserData()).thenAnswer((_) async => null);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);
      expect(state, isNull);
    });

    test('login exitoso actualiza estado a AuthUser', () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);
      when(
        () => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(_testUser));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'test@test.com', password: 'password123');

      final state = container.read(authNotifierProvider);
      expect(state, isA<AsyncData<AuthUser?>>());
      expect(state.value, _testUser);
    });

    test('login con credenciales inválidas produce AsyncError con UnauthorizedError',
        () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);
      when(
        () => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Failure(UnauthorizedError()));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'bad@test.com', password: 'wrong');

      final state = container.read(authNotifierProvider);
      expect(state, isA<AsyncError<AuthUser?>>());
      expect(state.error, isA<UnauthorizedError>());
    });

    test('logout limpia el estado a null', () async {
      when(() => mockStorage.readAccessToken()).thenAnswer((_) async => null);
      when(
        () => mockRepo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(_testUser));
      when(() => mockRepo.logout())
          .thenAnswer((_) async => const Success(null));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'test@test.com', password: 'password123');
      expect(container.read(authNotifierProvider).value, _testUser);

      await container.read(authNotifierProvider.notifier).logout();

      expect(container.read(authNotifierProvider).value, isNull);
    });
  });
}
