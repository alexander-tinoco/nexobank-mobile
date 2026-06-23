import 'package:nexobank_mobile/features/notifications/domain/models/app_notification.dart';

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        read: json['read'] as bool? ?? false,
        createdAt: json['created_at'] as String,
      );

  AppNotification toDomain() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: read,
        createdAt: DateTime.parse(createdAt),
      );
}
