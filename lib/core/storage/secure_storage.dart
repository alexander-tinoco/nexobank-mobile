import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
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

  Future<String?> readUserData() =>
      _storage.read(key: SecureStorageKeys.userData);

  Future<void> saveUserData(String json) =>
      _storage.write(key: SecureStorageKeys.userData, value: json);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: SecureStorageKeys.accessToken),
      _storage.delete(key: SecureStorageKeys.refreshToken),
      _storage.delete(key: SecureStorageKeys.userData),
    ]);
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage(FlutterSecureStorage());
});
