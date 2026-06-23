import 'package:nexobank_mobile/features/auth/data/dtos/login_response_dto.dart';
import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';

class RegisterResponseDto {
  const RegisterResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserDto user;

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      RegisterResponseDto(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );

  AuthUser get authUser => user.toDomain();
}
