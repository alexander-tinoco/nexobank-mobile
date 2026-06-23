import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/router/app_shell.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:nexobank_mobile/features/accounts/presentation/screens/home_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:nexobank_mobile/features/cards/presentation/screens/card_detail_screen.dart';
import 'package:nexobank_mobile/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:nexobank_mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:nexobank_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:nexobank_mobile/features/transfers/presentation/screens/transfer_confirm_screen.dart';
import 'package:nexobank_mobile/features/transfers/presentation/screens/transfer_form_screen.dart';
import 'package:nexobank_mobile/features/transfers/presentation/screens/transfer_result_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String accountDetail = '/accounts/:id';
  static const String cardDetail = '/cards/:id';
  static const String transfer = '/transfer';
  static const String transferConfirm = '/transfer/confirm';
  static const String transferResult = '/transfer/result';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
}

const _publicRoutes = {
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
};

/// ChangeNotifier that triggers GoRouter re-evaluation on auth state changes.
/// Auth features call [onAuthStateChanged] after login/logout.
class RouterAuthNotifier extends ChangeNotifier {
  void onAuthStateChanged() => notifyListeners();
}

final routerAuthNotifierProvider = Provider<RouterAuthNotifier>((ref) {
  return RouterAuthNotifier();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  final authNotifier = ref.read(routerAuthNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final token = await secureStorage.readAccessToken();
      final isAuthenticated = token != null && token.isNotEmpty;
      final location = state.matchedLocation;
      final isPublicRoute = _publicRoutes.contains(location);

      if (!isAuthenticated && !isPublicRoute && location != AppRoutes.splash) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isPublicRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Unauthenticated routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Authenticated routes wrapped in AppShell (BottomNavigationBar)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountDetail,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AccountDetailScreen(accountId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.cardDetail,
            builder: (context, state) {
              final cardId = state.pathParameters['id']!;
              // accountId is passed as extra when navigating to this route
              final accountId = (state.extra as String?) ?? '';
              return CardDetailScreen(accountId: accountId, cardId: cardId);
            },
          ),
          GoRoute(
            path: AppRoutes.transfer,
            builder: (context, state) => const TransferFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.transferConfirm,
            builder: (context, state) => TransferConfirmScreen(
              formData: state.extra! as TransferFormData,
            ),
          ),
          GoRoute(
            path: AppRoutes.transferResult,
            builder: (context, state) => const TransferResultScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationCenterScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
