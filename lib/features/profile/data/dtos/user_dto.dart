import 'package:nexobank_mobile/features/profile/domain/models/user_profile.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String createdAt;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as String,
        name: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        createdAt: json['created_at'] as String,
      );

  UserProfile toDomain() => UserProfile(
        id: id,
        name: name,
        email: email,
        phone: phone,
        createdAt: DateTime.parse(createdAt),
      );
}
