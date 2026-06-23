import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/accounts/data/account_repository_impl.dart';
import 'package:nexobank_mobile/features/accounts/domain/account_repository.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  late AccountRepository _repository;

  @override
  Future<List<Account>> build() async {
    _repository = ref.watch(accountRepositoryProvider);
    return _load();
  }

  Future<List<Account>> _load() async {
    final result = await _repository.getAccounts();
    return result.when(
      success: (List<Account> accounts) => accounts,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final accountsNotifierProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(
  AccountsNotifier.new,
);
