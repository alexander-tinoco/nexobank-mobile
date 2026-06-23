import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:nexobank_mobile/features/notifications/presentation/widgets/notification_item_widget.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          // WS connection indicator
          state.when(
            data: (s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.circle,
                size: 12,
                color: s.isConnected ? AppColors.turquoise : Colors.grey,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          TextButton(
            onPressed: () =>
                ref.read(notificationsNotifierProvider.notifier).markAllRead(),
            child: const Text(
              'Marcar leídas',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) {
          if (s.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay notificaciones',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: s.notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                NotificationItemWidget(notification: s.notifications[index]),
          );
        },
      ),
    );
  }
}
