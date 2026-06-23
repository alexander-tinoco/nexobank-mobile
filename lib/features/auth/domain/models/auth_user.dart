import 'dart:convert';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  String toJsonString() => jsonEncode({
        'id': id,
        'name': name,
        'email': email,
      });

  static AuthUser? fromJsonString(String? json) {
    if (json == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
