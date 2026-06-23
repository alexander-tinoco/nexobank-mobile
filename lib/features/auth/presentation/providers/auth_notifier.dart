import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/router/app_router.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexobank_mobile/features/auth/domain/models/auth_user.dart';

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async => null;

  Future<void> checkSession() async {
    state = const AsyncLoading();
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readAccessToken();
    if (token == null || token.isEmpty) {
      state = const AsyncData(null);
      ref.read(routerAuthNotifierProvider).onAuthStateChanged();
      return;
    }
    final userJson = await storage.readUserData();
    final user = AuthUser.fromJsonString(userJson);
    state = AsyncData(user);
    ref.read(routerAuthNotifierProvider).onAuthStateChanged();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final result =
        await ref.read(authRepositoryProvider).login(email: email, password: password);
    switch (result) {
      case Success<AuthUser>(:final value):
        state = AsyncData(value);
        ref.read(routerAuthNotifierProvider).onAuthStateChanged();
      case Failure<AuthUser>(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .register(name: name, email: email, password: password);
    switch (result) {
      case Success<AuthUser>(:final value):
        state = AsyncData(value);
        ref.read(routerAuthNotifierProvider).onAuthStateChanged();
      case Failure<AuthUser>(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
    ref.read(routerAuthNotifierProvider).onAuthStateChanged();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);
