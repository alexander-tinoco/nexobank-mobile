class UserProfile {
  const UserProfile({
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
  final DateTime createdAt;
}
