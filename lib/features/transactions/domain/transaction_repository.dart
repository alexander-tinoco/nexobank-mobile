import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transactions/data/dtos/transaction_page_dto.dart';

abstract interface class TransactionRepository {
  Future<Result<TransactionPageDto>> getTransactions({
    required String accountId,
    String? cursor,
    int limit = 20,
  });
}
