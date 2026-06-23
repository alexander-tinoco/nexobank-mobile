import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/features/accounts/data/dtos/account_dto.dart';
import 'package:nexobank_mobile/features/accounts/data/dtos/account_list_dto.dart';
import 'package:nexobank_mobile/features/accounts/domain/account_repository.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Account>>> getAccounts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('accounts');
      final dto = AccountListDto.fromJson(response.data!);
      return Success(dto.toDomain());
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : const NetworkError('Error desconocido'));
    }
  }

  @override
  Future<Result<Account>> getAccountById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('accounts/$id');
      final dto = AccountDto.fromJson(response.data!);
      return Success(dto.toDomain());
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : const NetworkError('Error desconocido'));
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return AccountRepositoryImpl(dio);
});
