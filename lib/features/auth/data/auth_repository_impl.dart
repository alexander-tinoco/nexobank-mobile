import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/auth/data/dtos/login_request_dto.dart';
import 'package:nexobank_mobile/features/auth/data/dtos/login_response_dto.dart';
import 'package:nexobank_mobile/features/auth/data/dtos/register_request_dto.dart';
import 'package:nexobank_mobile/features/auth/data/dtos/register_response_dto.dart';
import 'package:nexobank_mobile/features/auth/domain/auth_repository.dart';
import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.dioClient,
    required this.secureStorage,
  });

  final DioClient dioClient;
  final SecureStorage secureStorage;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: LoginRequestDto(email: email, password: password).toJson(),
      );
      final dto = LoginResponseDto.fromJson(response.data!);
      final user = dto.user.toDomain();
      await Future.wait([
        secureStorage.saveTokens(
          accessToken: dto.accessToken,
          refreshToken: dto.refreshToken,
        ),
        secureStorage.saveUserData(user.toJsonString()),
      ]);
      return Success(user);
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''));
    }
  }

  @override
  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: RegisterRequestDto(name: name, email: email, password: password).toJson(),
      );
      final dto = RegisterResponseDto.fromJson(response.data!);
      final user = dto.authUser;
      await Future.wait([
        secureStorage.saveTokens(
          accessToken: dto.accessToken,
          refreshToken: dto.refreshToken,
        ),
        secureStorage.saveUserData(user.toJsonString()),
      ]);
      return Success(user);
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await dioClient.dio.post<void>('/auth/logout');
      await secureStorage.clearTokens();
      return const Success(null);
    } on DioException catch (e) {
      // Clear tokens even if the server call fails
      await secureStorage.clearTokens();
      return Failure(e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''));
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await dioClient.dio.post<void>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await dioClient.dio.post<void>(
        '/auth/reset-password',
        data: {'token': token, 'new_password': newPassword},
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''));
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dioClient: ref.read(dioClientProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});
