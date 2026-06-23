import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/config/app_config.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/notifications/data/dtos/notification_dto.dart';
import 'package:nexobank_mobile/features/notifications/domain/models/app_notification.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationsState {
  const NotificationsState({
    required this.notifications,
    required this.unreadCount,
    required this.isConnected,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isConnected;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isConnected,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isConnected: isConnected ?? this.isConnected,
      );
}

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _disposed = false;
  int _reconnectAttempt = 0;
  final StreamController<AppNotification> _newNotificationController =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get newNotifications => _newNotificationController.stream;

  static const NotificationsState _emptyState = NotificationsState(
    notifications: [],
    unreadCount: 0,
    isConnected: false,
  );

  @override
  Future<NotificationsState> build() async {
    ref.onDispose(_cleanup);
    // Connect after first frame
    Future.microtask(connect);
    return _emptyState;
  }

  Future<void> connect() async {
    if (_disposed) return;
    final token = await ref.read(secureStorageProvider).readAccessToken();
    if (token == null) return;

    try {
      // wsUrl already ends with '/'; do NOT add a leading slash to the path.
      final uri = Uri.parse('${AppConfig.wsUrl}ws/notifications?token=$token');
      _channel = WebSocketChannel.connect(uri);
      // Await handshake so upgrade failures are caught by the try/catch.
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _onDone,
        cancelOnError: false,
      );

      _reconnectAttempt = 0;
      _updateState((s) => s.copyWith(isConnected: true));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final notification = NotificationDto.fromJson(json).toDomain();
      final current = state.value ?? _emptyState;
      final updated = current.copyWith(
        notifications: [notification, ...current.notifications],
        unreadCount: current.unreadCount + 1,
      );
      state = AsyncData(updated);
      _newNotificationController.add(notification);
    } catch (_) {
      // Malformed payload — ignore
    }
  }

  void _onDone() {
    if (_disposed) return;
    final closeCode = _channel?.closeCode;
    if (closeCode == 4001) {
      _forceLogout();
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _updateState((s) => s.copyWith(isConnected: false));
    final delaySeconds = _backoffSeconds();
    _reconnectAttempt++;
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (!_disposed) connect();
    });
  }

  int _backoffSeconds() {
    const delays = [1, 2, 4, 8, 16, 30];
    final idx = _reconnectAttempt.clamp(0, delays.length - 1);
    return delays[idx];
  }

  void _forceLogout() {
    ref.read(secureStorageProvider).clearTokens();
    ref.read(routerAuthNotifierProvider).onAuthStateChanged();
    _cleanup();
  }

  Future<void> disconnect() async {
    _cleanup();
  }

  void markAllRead() {
    final current = state.value ?? _emptyState;
    final updated = current.copyWith(
      unreadCount: 0,
      notifications: current.notifications
          .map(
            (n) => AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList(),
    );
    state = AsyncData(updated);
  }

  void _updateState(NotificationsState Function(NotificationsState) updater) {
    final current = state.value ?? _emptyState;
    state = AsyncData(updater(current));
  }

  void _cleanup() {
    _disposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    _newNotificationController.close();
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
