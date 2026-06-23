import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/notifications/presentation/providers/notifications_notifier.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    when(
      () => mockStorage.read(key: SecureStorageKeys.accessToken),
    ).thenAnswer((_) async => 'test_token');
    when(
      () => mockStorage.read(key: SecureStorageKeys.refreshToken),
    ).thenAnswer((_) async => null);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(SecureStorage(mockStorage)),
        ],
      );

  group('NotificationsNotifier', () {
    test('initial state has empty notifications and zero unreadCount', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationsNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(notificationsNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.notifications, isEmpty);
      expect(state.value!.unreadCount, 0);
    });

    test('markAllRead sets unreadCount to 0', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationsNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      container.read(notificationsNotifierProvider.notifier).markAllRead();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(notificationsNotifierProvider);
      expect(state.value?.unreadCount, 0);
    });

    test('disconnect can be called without error', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationsNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await expectLater(
        container.read(notificationsNotifierProvider.notifier).disconnect(),
        completes,
      );
    });
  });
}
