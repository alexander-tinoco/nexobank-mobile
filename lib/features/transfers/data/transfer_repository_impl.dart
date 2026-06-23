import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_request_dto.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_response_dto.dart';
import 'package:nexobank_mobile/features/transfers/domain/models/transfer.dart';
import 'package:nexobank_mobile/features/transfers/domain/transfer_repository.dart';

class TransferRepositoryImpl implements TransferRepository {
  const TransferRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<Transfer>> executeTransfer(TransferRequestDto dto) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'transfers',
        data: dto.toJson(),
      );
      final transfer =
          TransferResponseDto.fromJson(response.data!).toDomain();
      return Success(transfer);
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppError) return Failure(error);
      return Failure(NetworkError(e.message ?? 'Error de red'));
    }
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepositoryImpl(ref.read(dioClientProvider).dio);
});
