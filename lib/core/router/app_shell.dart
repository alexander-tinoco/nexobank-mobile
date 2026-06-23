import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/theme/app_colors.dart';
import 'package:nexobank_mobile/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:nexobank_mobile/features/notifications/presentation/widgets/notification_badge_widget.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabIndexForLocation(location);
    final unreadCount = ref.watch(
      notificationsNotifierProvider.select(
        (s) => s.valueOrNull?.unreadCount ?? 0,
      ),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.brandDeep,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onTabSelected(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.onPrimary),
            selectedIcon: Icon(Icons.home, color: AppColors.onPrimary),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined, color: AppColors.onPrimary),
            selectedIcon: Icon(Icons.swap_horiz, color: AppColors.onPrimary),
            label: 'Transferir',
          ),
          NavigationDestination(
            icon: NotificationBadgeWidget(
              count: unreadCount,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.onPrimary,
              ),
            ),
            selectedIcon: NotificationBadgeWidget(
              count: unreadCount,
              child: const Icon(
                Icons.notifications,
                color: AppColors.onPrimary,
              ),
            ),
            label: 'Notificaciones',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.onPrimary),
            selectedIcon: Icon(Icons.person, color: AppColors.onPrimary),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.transfer);
      case 2:
        context.go(AppRoutes.notifications);
      case 3:
        context.go(AppRoutes.profile);
    }
  }

  int _tabIndexForLocation(String location) {
    if (location.startsWith('/home') || location.startsWith('/accounts')) {
      return 0;
    }
    if (location.startsWith('/transfer') || location.startsWith('/cards')) {
      return 1;
    }
    if (location.startsWith('/notifications')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }
}
