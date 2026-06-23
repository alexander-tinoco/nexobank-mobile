// API returns only tokens — same shape as login response
class RegisterResponseDto {
  const RegisterResponseDto({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      RegisterResponseDto(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
