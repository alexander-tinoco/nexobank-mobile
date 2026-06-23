import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  AuthUser toDomain() => AuthUser(id: id, name: name, email: email);
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserDto user;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      LoginResponseDto(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );
}
