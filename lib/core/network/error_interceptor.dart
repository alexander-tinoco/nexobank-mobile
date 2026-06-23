import 'package:dio/dio.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';

class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor({this.onNetworkError, this.onNetworkSuccess});

  /// Called when a timeout or connection error is detected, so the UI can
  /// show an offline banner.
  final void Function()? onNetworkError;

  /// Called on every successful response to dismiss the offline banner.
  final void Function()? onNetworkSuccess;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    onNetworkSuccess?.call();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = _toAppError(err);
    if (appError is NetworkError) {
      onNetworkError?.call();
    }
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appError,
        type: err.type,
        response: err.response,
      ),
    );
  }

  AppError _toAppError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkError('No hay conexión a internet');
    }

    final response = err.response;
    if (response == null) {
      return NetworkError(err.message ?? 'Error desconocido de red');
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final errorCode = data['error_code'] as String?;
      final message = (data['message'] as String?) ?? 'Error desconocido';
      return _fromErrorCode(errorCode, message);
    }

    return UnknownError(
      response.statusCode?.toString() ?? 'UNKNOWN',
      'Error del servidor: ${response.statusCode}',
    );
  }

  AppError _fromErrorCode(String? code, String message) => switch (code) {
        'INSUFFICIENT_FUNDS' => const InsufficientFundsError(),
        'ACCOUNT_NOT_FOUND' => const AccountNotFoundError(),
        'CARD_FROZEN' => const CardFrozenError(),
        'UNAUTHORIZED' => const UnauthorizedError(),
        'SESSION_EXPIRED' => const SessionExpiredError(),
        _ => UnknownError(code ?? 'UNKNOWN', message),
      };
}
