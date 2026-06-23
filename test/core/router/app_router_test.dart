import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockPlugin;

  setUp(() {
    mockPlugin = MockFlutterSecureStorage();
  });

  ProviderContainer makeContainer({String? accessToken}) {
    when(
      () => mockPlugin.read(key: SecureStorageKeys.accessToken),
    ).thenAnswer((_) async => accessToken);
    when(
      () => mockPlugin.read(key: SecureStorageKeys.refreshToken),
    ).thenAnswer((_) async => null);

    return ProviderContainer(
      overrides: [
        secureStorageProvider
            .overrideWithValue(SecureStorage(mockPlugin)),
      ],
    );
  }

  GoRouter getRouter(ProviderContainer container) =>
      container.read(appRouterProvider);

  group('auth guard', () {
    testWidgets(
      'unauthenticated user navigating to /home is redirected to /login',
      (tester) async {
        final container = makeContainer(accessToken: null);
        addTearDown(container.dispose);
        final router = getRouter(container);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        router.go(AppRoutes.home);
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.fullPath, AppRoutes.login);
      },
    );

    testWidgets(
      'authenticated user navigating to /home is allowed through',
      (tester) async {
        final container = makeContainer(accessToken: 'valid_token');
        addTearDown(container.dispose);
        final router = getRouter(container);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        router.go(AppRoutes.home);
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.fullPath, AppRoutes.home);
      },
    );

    testWidgets(
      'authenticated user on /login is redirected to /home',
      (tester) async {
        final container = makeContainer(accessToken: 'valid_token');
        addTearDown(container.dispose);
        final router = getRouter(container);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        router.go(AppRoutes.login);
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.fullPath, AppRoutes.home);
      },
    );
  });
}
