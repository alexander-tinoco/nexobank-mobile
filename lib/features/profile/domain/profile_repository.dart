import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/profile/data/dtos/update_profile_request_dto.dart';
import 'package:nexobank_mobile/features/profile/domain/models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> getProfile();
  Future<Result<UserProfile>> updateProfile(UpdateProfileRequestDto dto);
}
