import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';
import 'package:nexobank_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:nexobank_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:nexobank_mobile/features/auth/presentation/widgets/nexo_primary_button.dart';

class FakeAuthNotifier extends AuthNotifier {
  // build() is overridden so the widget test doesn't call secureStorageProvider
  // (FlutterSecureStorage has no platform channel in the test environment).
  @override
  Future<AuthUser?> build() async => null;

  void setError(Object err) {
    state = AsyncError(err, StackTrace.current);
  }

  void setLoading() {
    state = const AsyncLoading();
  }
}

Widget buildTestApp(ProviderContainer container) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) =>
            const Scaffold(body: Text('Forgot Password')),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const Scaffold(body: Text('Register')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('muestra SnackBar con mensaje de error tras AsyncError', (tester) async {
    final notifier = FakeAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => notifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    notifier.setError(const UnauthorizedError());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('botón muestra CircularProgressIndicator durante loading', (tester) async {
    final notifier = FakeAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => notifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    expect(find.byType(NexoPrimaryButton), findsOneWidget);

    notifier.setLoading();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('NetworkError muestra mensaje de sin conexión', (tester) async {
    final notifier = FakeAuthNotifier();
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => notifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container));
    await tester.pumpAndSettle();

    notifier.setError(const NetworkError('timeout'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Sin conexión'), findsOneWidget);
  });
}
