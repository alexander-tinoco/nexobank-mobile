import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_request_dto.dart';
import 'package:nexobank_mobile/features/transfers/data/transfer_repository_impl.dart';
import 'package:nexobank_mobile/features/transfers/domain/models/transfer.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late TransferRepositoryImpl sut;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    sut = TransferRepositoryImpl(mockDio);
  });

  const dto = TransferRequestDto(
    amount: '500.00',
    destinationAccountId: 'acc-dest',
    idempotencyKey: 'uuid-abc-123',
  );

  final successResponse = Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: '/transfers'),
    statusCode: 200,
    data: {
      'id': 'txn-1',
      'amount': '500.00',
      'status': 'completed',
      'origin_account_id': 'acc-origin',
      'destination_account_id': 'acc-dest',
      'created_at': '2026-06-23T10:00:00Z',
      'idempotency_key': 'uuid-abc-123',
    },
  );

  group('executeTransfer', () {
    test('calls POST /transfers with correct idempotency_key', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/transfers',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => successResponse);

      await sut.executeTransfer(dto);

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/transfers',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final body = captured.first as Map<String, dynamic>;
      expect(body['idempotency_key'], 'uuid-abc-123');
      expect(body['amount'], '500.00');
      expect(body['destination_account_id'], 'acc-dest');
    });

    test('returns Success<Transfer> on 200', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/transfers',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => successResponse);

      final result = await sut.executeTransfer(dto);

      expect(result, isA<Success<Transfer>>());
      expect((result as Success<Transfer>).value.id, 'txn-1');
    });

    test('returns Failure with AppError when DioException carries AppError',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/transfers',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/transfers'),
          error: const InsufficientFundsError(),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await sut.executeTransfer(dto);

      expect(result, isA<Failure<Transfer>>());
      expect((result as Failure<Transfer>).error, isA<InsufficientFundsError>());
    });

    test('returns Failure<NetworkError> on connection error', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/transfers',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/transfers'),
          type: DioExceptionType.connectionError,
          message: 'No connection',
        ),
      );

      final result = await sut.executeTransfer(dto);

      expect(result, isA<Failure<Transfer>>());
      expect((result as Failure<Transfer>).error, isA<NetworkError>());
    });
  });
}
