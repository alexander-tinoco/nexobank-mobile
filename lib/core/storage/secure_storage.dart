import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}

class SecureStorage {
  const SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() =>
      _storage.read(key: SecureStorageKeys.accessToken);

  Future<String?> readRefreshToken() =>
      _storage.read(key: SecureStorageKeys.refreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: SecureStorageKeys.accessToken, value: accessToken),
      _storage.write(key: SecureStorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: SecureStorageKeys.accessToken),
      _storage.delete(key: SecureStorageKeys.refreshToken),
    ]);
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage(FlutterSecureStorage());
});
