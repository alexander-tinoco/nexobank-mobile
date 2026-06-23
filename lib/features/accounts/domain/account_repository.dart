import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

abstract interface class AccountRepository {
  Future<Result<List<Account>>> getAccounts();
  Future<Result<Account>> getAccountById(String id);
}
