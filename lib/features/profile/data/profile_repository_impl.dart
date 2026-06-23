import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/features/profile/data/dtos/update_profile_request_dto.dart';
import 'package:nexobank_mobile/features/profile/data/dtos/user_dto.dart';
import 'package:nexobank_mobile/features/profile/domain/models/user_profile.dart';
import 'package:nexobank_mobile/features/profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<UserProfile>> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      final dto = UserDto.fromJson(response.data!);
      return Success(dto.toDomain());
    } on DioException catch (e) {
      return Failure(
        e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''),
      );
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(UpdateProfileRequestDto dto) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: dto.toJson(),
      );
      final userDto = UserDto.fromJson(response.data!);
      return Success(userDto.toDomain());
    } on DioException catch (e) {
      return Failure(
        e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''),
      );
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.read(dioClientProvider);
  return ProfileRepositoryImpl(client.dio);
});
