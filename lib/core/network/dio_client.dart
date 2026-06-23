import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/config/app_config.dart';
import 'package:nexobank_mobile/core/network/auth_interceptor.dart';
import 'package:nexobank_mobile/core/network/error_interceptor.dart';
import 'package:nexobank_mobile/core/network/logging_interceptor.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/core/widgets/offline_banner.dart';

class DioClient {
  DioClient({
    required SecureStorage secureStorage,
    required Future<void> Function() onLogout,
    void Function()? onNetworkError,
    void Function()? onNetworkSuccess,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        secureStorage: secureStorage,
        dio: _dio,
        onLogout: onLogout,
      ),
      ErrorInterceptor(
        onNetworkError: onNetworkError,
        onNetworkSuccess: onNetworkSuccess,
      ),
      LoggingInterceptor(),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;
}

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  final authNotifier = ref.read(routerAuthNotifierProvider);

  return DioClient(
    secureStorage: secureStorage,
    onLogout: () async {
      await secureStorage.clearTokens();
      authNotifier.onAuthStateChanged();
    },
    onNetworkError: () => ref.read(offlineBannerProvider.notifier).state = true,
    onNetworkSuccess: () => ref.read(offlineBannerProvider.notifier).state = false,
  );
});
