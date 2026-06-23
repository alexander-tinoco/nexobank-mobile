import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/accounts/data/account_repository_impl.dart';
import 'package:nexobank_mobile/features/accounts/domain/account_repository.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

// Placeholder — the auth feature will override this with the authenticated user's id.
final currentUserIdProvider = Provider<String>((ref) => '');

class AccountDetailNotifier extends FamilyAsyncNotifier<Account, String> {
  late AccountRepository _repository;

  @override
  Future<Account> build(String accountId) async {
    _repository = ref.watch(accountRepositoryProvider);
    return _load(accountId);
  }

  Future<Account> _load(String accountId) async {
    final result = await _repository.getAccountById(accountId);
    return result.when(
      success: (Account account) {
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId.isNotEmpty && account.ownerId != currentUserId) {
          throw Exception('Acceso no autorizado a esta cuenta');
        }
        return account;
      },
      failure: (error) => throw error,
    );
  }
}

final accountDetailNotifierProvider =
    AsyncNotifierProviderFamily<AccountDetailNotifier, Account, String>(
  AccountDetailNotifier.new,
);
