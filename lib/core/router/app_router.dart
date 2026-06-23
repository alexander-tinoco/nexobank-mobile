import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/splash_screen.dart';

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
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _PlaceholderScreen(label: 'Home'),
      ),
      GoRoute(
        path: AppRoutes.accountDetail,
        builder: (context, state) =>
            _PlaceholderScreen(label: 'Account ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoutes.cardDetail,
        builder: (context, state) =>
            _PlaceholderScreen(label: 'Card ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoutes.transfer,
        builder: (context, state) =>
            const _PlaceholderScreen(label: 'Transfer Form'),
      ),
      GoRoute(
        path: AppRoutes.transferConfirm,
        builder: (context, state) =>
            const _PlaceholderScreen(label: 'Transfer Confirm'),
      ),
      GoRoute(
        path: AppRoutes.transferResult,
        builder: (context, state) =>
            const _PlaceholderScreen(label: 'Transfer Result'),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) =>
            const _PlaceholderScreen(label: 'Notifications'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) =>
            const _PlaceholderScreen(label: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) =>
            const _PlaceholderScreen(label: 'Edit Profile'),
      ),
    ],
  );
});

// Temporary screen builders. Feature agents replace these with real screens.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );
  }
}
