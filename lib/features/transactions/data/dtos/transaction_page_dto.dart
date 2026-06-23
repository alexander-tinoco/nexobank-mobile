import 'package:nexobank_mobile/features/transactions/data/dtos/transaction_dto.dart';

class TransactionPageDto {
  const TransactionPageDto({
    required this.transactions,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<TransactionDto> transactions;
  final String? nextCursor;
  final bool hasMore;

  factory TransactionPageDto.fromJson(Map<String, dynamic> json) =>
      TransactionPageDto(
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor'] as String?,
        hasMore: json['has_more'] as bool,
      );
}
