import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/main.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  testWidgets('NexoBankApp renders without crash', (WidgetTester tester) async {
    final mockPlugin = MockFlutterSecureStorage();
    when(
      () => mockPlugin.read(key: SecureStorageKeys.accessToken),
    ).thenAnswer((_) async => null);
    when(
      () => mockPlugin.read(key: SecureStorageKeys.refreshToken),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(SecureStorage(mockPlugin)),
        ],
        child: const NexoBankApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
