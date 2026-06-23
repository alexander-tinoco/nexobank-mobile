import 'package:flutter/material.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/notifications/domain/models/app_notification.dart';

class NotificationItemWidget extends StatelessWidget {
  const NotificationItemWidget({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? null : AppColors.brand.withAlpha(20),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.brandDeep.withAlpha(30),
          child: Icon(_iconForType(notification.type), color: AppColors.brandDeep),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 2),
            Text(
              _relativeTime(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
        'transfer_received' => Icons.arrow_downward,
        'transfer_sent' => Icons.arrow_upward,
        'account_update' => Icons.account_balance,
        _ => Icons.notifications,
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }
}
