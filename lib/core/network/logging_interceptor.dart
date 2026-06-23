import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  static const _sensitiveHeaders = {'authorization', 'cookie'};
  static const _sensitiveBodyFields = {
    'password',
    'new_password',
    'token',
    'refresh_token',
    'card_number',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers)
        ..removeWhere((k, _) => _sensitiveHeaders.contains(k.toLowerCase()));
      debugPrint('[DIO] → ${options.method} ${options.path}');
      debugPrint('[DIO]   Headers: $sanitizedHeaders');
      if (options.data != null) {
        debugPrint('[DIO]   Body: ${_sanitizeData(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO] ← ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[DIO] ✕ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}',
      );
    }
    handler.next(err);
  }

  dynamic _sanitizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return {
        for (final entry in data.entries)
          entry.key: _sensitiveBodyFields.contains(entry.key) ? '***' : entry.value,
      };
    }
    return data;
  }
}
