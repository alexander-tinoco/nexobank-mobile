import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/network/error_interceptor.dart';

void main() {
  late ErrorInterceptor sut;

  setUp(() {
    sut = const ErrorInterceptor();
  });

  DioException makeError({
    int? statusCode,
    dynamic data,
    DioExceptionType type = DioExceptionType.badResponse,
    String? message,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: statusCode != null
          ? Response<dynamic>(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: statusCode,
              data: data,
            )
          : null,
      type: type,
      message: message,
    );
  }

  group('network errors', () {
    test('connectionTimeout → NetworkError', () {
      final handler = CapturingHandler();
      sut.onError(makeError(type: DioExceptionType.connectionTimeout), handler);
      expect(handler.captured, isA<NetworkError>());
    });

    test('receiveTimeout → NetworkError', () {
      final handler = CapturingHandler();
      sut.onError(makeError(type: DioExceptionType.receiveTimeout), handler);
      expect(handler.captured, isA<NetworkError>());
    });

    test('connectionError → NetworkError', () {
      final handler = CapturingHandler();
      sut.onError(makeError(type: DioExceptionType.connectionError), handler);
      expect(handler.captured, isA<NetworkError>());
    });
  });

  group('backend error_code mapping', () {
    void expectErrorCode(String code, Type expectedType) {
      final handler = CapturingHandler();
      sut.onError(
        makeError(
          statusCode: 400,
          data: <String, dynamic>{'error_code': code, 'message': 'msg'},
        ),
        handler,
      );
      expect(handler.captured.runtimeType, expectedType);
    }

    test('INSUFFICIENT_FUNDS', () {
      expectErrorCode('INSUFFICIENT_FUNDS', InsufficientFundsError);
    });

    test('ACCOUNT_NOT_FOUND', () {
      expectErrorCode('ACCOUNT_NOT_FOUND', AccountNotFoundError);
    });

    test('CARD_FROZEN', () {
      expectErrorCode('CARD_FROZEN', CardFrozenError);
    });

    test('UNAUTHORIZED', () {
      expectErrorCode('UNAUTHORIZED', UnauthorizedError);
    });

    test('SESSION_EXPIRED', () {
      expectErrorCode('SESSION_EXPIRED', SessionExpiredError);
    });

    test('unknown code → UnknownError with the code', () {
      final handler = CapturingHandler();
      sut.onError(
        makeError(
          statusCode: 422,
          data: <String, dynamic>{
            'error_code': 'SOME_NEW_CODE',
            'message': 'something',
          },
        ),
        handler,
      );
      expect(handler.captured, isA<UnknownError>());
      expect((handler.captured! as UnknownError).code, 'SOME_NEW_CODE');
    });
  });

  group('edge cases', () {
    test('non-map response body → UnknownError', () {
      final handler = CapturingHandler();
      sut.onError(
        makeError(statusCode: 500, data: 'Internal Server Error'),
        handler,
      );
      expect(handler.captured, isA<UnknownError>());
    });

    test('null response → NetworkError with message', () {
      final handler = CapturingHandler();
      sut.onError(
        DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.unknown,
          message: 'socket error',
        ),
        handler,
      );
      expect(handler.captured, isA<NetworkError>());
    });
  });
}

class CapturingHandler extends ErrorInterceptorHandler {
  AppError? captured;

  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {
    captured = err.error as AppError?;
  }
}
