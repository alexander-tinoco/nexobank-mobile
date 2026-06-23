import 'package:nexobank_mobile/core/errors/result.dart';

abstract interface class NotificationRepository {
  Future<Result<void>> registerDeviceToken(String token);
}
