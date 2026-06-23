import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/features/transactions/data/dtos/transaction_page_dto.dart';
import 'package:nexobank_mobile/features/transactions/domain/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<TransactionPageDto>> getTransactions({
    required String accountId,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/accounts/$accountId/transactions',
        queryParameters: queryParams,
      );
      return Success(TransactionPageDto.fromJson(response.data!));
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppError) return Failure(error);
      return Failure(NetworkError(e.message ?? 'Error de red'));
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(dioClientProvider).dio);
});
