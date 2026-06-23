import 'package:nexobank_mobile/features/transactions/domain/models/transaction.dart';

class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.balanceAfter,
  });

  final String id;
  final String type;
  final String amount;
  final String description;
  final String status;
  final String createdAt;
  final String balanceAfter;

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: json['amount'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        balanceAfter: json['balance_after'] as String,
      );

  Transaction toDomain() => Transaction(
        id: id,
        type: type,
        amount: amount,
        description: description,
        status: status,
        createdAt: createdAt,
        balanceAfter: balanceAfter,
      );
}
