import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/profile/data/dtos/update_profile_request_dto.dart';
import 'package:nexobank_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nexobank_mobile/features/profile/domain/models/user_profile.dart';
import 'package:nexobank_mobile/features/profile/domain/profile_repository.dart';
import 'package:nexobank_mobile/features/profile/presentation/screens/edit_profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

final _testProfile = UserProfile(
  id: 'u1',
  name: 'Juan Pérez',
  email: 'juan@example.com',
  createdAt: DateTime(2025),
);

void main() {
  late MockProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockProfileRepository();
  });

  setUpAll(() {
    registerFallbackValue(const UpdateProfileRequestDto());
  });

  Widget buildApp(MockProfileRepository repo) => ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: EditProfileScreen()),
      );

  testWidgets('shows validation error when name is empty', (tester) async {
    when(() => mockRepo.getProfile())
        .thenAnswer((_) async => Success(_testProfile));

    await tester.pumpWidget(buildApp(mockRepo));
    await tester.pumpAndSettle();

    // Clear the name field
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
  });

  testWidgets('shows SnackBar on successful save', (tester) async {
    when(() => mockRepo.getProfile())
        .thenAnswer((_) async => Success(_testProfile));

    final updatedProfile = UserProfile(
      id: 'u1',
      name: 'Nuevo Nombre',
      email: 'juan@example.com',
      createdAt: DateTime(2025),
    );
    when(() => mockRepo.updateProfile(any()))
        .thenAnswer((_) async => Success(updatedProfile));

    await tester.pumpWidget(buildApp(mockRepo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Nuevo Nombre');
    await tester.tap(find.byType(ElevatedButton));
    // pump enough for the async save + SnackBar animation to start
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Perfil actualizado'), findsOneWidget);
  });
}
