import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<void>> forgotPassword({required String email});

  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  });
}
