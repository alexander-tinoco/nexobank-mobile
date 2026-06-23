import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/profile/data/dtos/update_profile_request_dto.dart';
import 'package:nexobank_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nexobank_mobile/features/profile/domain/models/user_profile.dart';
import 'package:nexobank_mobile/features/profile/domain/profile_repository.dart';

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  late final ProfileRepository _repo;

  @override
  Future<UserProfile?> build() async {
    _repo = ref.read(profileRepositoryProvider);
    final result = await _repo.getProfile();
    return switch (result) {
      Success<UserProfile>(value: final v) => v,
      Failure<UserProfile>(error: final e) => throw e,
    };
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final dto = UpdateProfileRequestDto(name: name, phone: phone);
    final result = await _repo.updateProfile(dto);
    switch (result) {
      case Success<UserProfile>(value: final updated):
        state = AsyncData(updated);
      case Failure<UserProfile>(error: final e):
        throw e;
    }
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);
