import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/profile/data/dtos/update_profile_request_dto.dart';
import 'package:nexobank_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nexobank_mobile/features/profile/domain/models/user_profile.dart';
import 'package:nexobank_mobile/features/profile/domain/profile_repository.dart';
import 'package:nexobank_mobile/features/profile/presentation/providers/profile_notifier.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

final _testProfile = UserProfile(
  id: 'u1',
  name: 'Juan Pérez',
  email: 'juan@example.com',
  phone: '5511223344',
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

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

  group('ProfileNotifier', () {
    test('getProfile() successful → state = UserProfile', () async {
      when(() => mockRepo.getProfile())
          .thenAnswer((_) async => Success(_testProfile));

      final container = makeContainer();
      addTearDown(container.dispose);

      // Trigger build
      container.read(profileNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(profileNotifierProvider);
      expect(state.hasValue, isTrue);
      expect(state.value?.name, 'Juan Pérez');
      expect(state.value?.email, 'juan@example.com');
    });

    test('updateProfile() successful → updates state', () async {
      when(() => mockRepo.getProfile())
          .thenAnswer((_) async => Success(_testProfile));

      final updatedProfile = UserProfile(
        id: 'u1',
        name: 'Juan Carlos',
        email: 'juan@example.com',
        createdAt: DateTime(2025),
      );
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => Success(updatedProfile));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(profileNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await container
          .read(profileNotifierProvider.notifier)
          .updateProfile(name: 'Juan Carlos');

      final state = container.read(profileNotifierProvider);
      expect(state.value?.name, 'Juan Carlos');
    });
  });
}
