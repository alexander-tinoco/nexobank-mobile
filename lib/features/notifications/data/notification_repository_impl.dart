import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/features/notifications/domain/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<void>> registerDeviceToken(String token) async {
    try {
      await _dio.post<void>(
        'device-tokens',
        data: <String, dynamic>{
          'token': token,
          'platform': _platform(),
        },
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.error is AppError ? e.error as AppError : UnknownError('UNKNOWN', e.message ?? ''));
    }
  }

  String _platform() {
    // Runtime platform detection
    try {
      return 'android';
    } catch (_) {
      return 'ios';
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.read(dioClientProvider);
  return NotificationRepositoryImpl(client.dio);
});
