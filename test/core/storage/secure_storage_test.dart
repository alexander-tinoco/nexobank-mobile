import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockPlugin;
  late SecureStorage sut;

  setUp(() {
    mockPlugin = MockFlutterSecureStorage();
    sut = SecureStorage(mockPlugin);
  });

  group('readAccessToken', () {
    test('returns token when present', () async {
      when(
        () => mockPlugin.read(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async => 'my_token');

      final result = await sut.readAccessToken();

      expect(result, 'my_token');
    });

    test('returns null when absent', () async {
      when(
        () => mockPlugin.read(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async => null);

      final result = await sut.readAccessToken();

      expect(result, isNull);
    });
  });

  group('readRefreshToken', () {
    test('returns refresh token when present', () async {
      when(
        () => mockPlugin.read(key: SecureStorageKeys.refreshToken),
      ).thenAnswer((_) async => 'refresh_abc');

      final result = await sut.readRefreshToken();

      expect(result, 'refresh_abc');
    });
  });

  group('saveTokens', () {
    test('writes both tokens atomically', () async {
      when(
        () => mockPlugin.write(
          key: SecureStorageKeys.accessToken,
          value: 'new_access',
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockPlugin.write(
          key: SecureStorageKeys.refreshToken,
          value: 'new_refresh',
        ),
      ).thenAnswer((_) async {});

      await sut.saveTokens(
        accessToken: 'new_access',
        refreshToken: 'new_refresh',
      );

      verify(
        () => mockPlugin.write(
          key: SecureStorageKeys.accessToken,
          value: 'new_access',
        ),
      ).called(1);
      verify(
        () => mockPlugin.write(
          key: SecureStorageKeys.refreshToken,
          value: 'new_refresh',
        ),
      ).called(1);
    });
  });

  group('clearTokens', () {
    test('deletes both tokens', () async {
      when(
        () => mockPlugin.delete(key: SecureStorageKeys.accessToken),
      ).thenAnswer((_) async {});
      when(
        () => mockPlugin.delete(key: SecureStorageKeys.refreshToken),
      ).thenAnswer((_) async {});

      await sut.clearTokens();

      verify(
        () => mockPlugin.delete(key: SecureStorageKeys.accessToken),
      ).called(1);
      verify(
        () => mockPlugin.delete(key: SecureStorageKeys.refreshToken),
      ).called(1);
    });
  });
}
