import 'package:dio/dio.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.dio,
    required this.onLogout,
  });

  final SecureStorage secureStorage;
  final Dio dio;
  final Future<void> Function() onLogout;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await secureStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid infinite loop on the refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh')) {
      await onLogout();
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await secureStorage.readRefreshToken();
      if (refreshToken == null) {
        await onLogout();
        handler.next(err);
        return;
      }

      // Use a clean Dio instance to avoid re-triggering this interceptor
      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data!;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;

      await secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await onLogout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
