import 'package:nexobank_mobile/features/transfers/domain/models/transfer.dart';

class TransferResponseDto {
  const TransferResponseDto({
    required this.id,
    required this.amount,
    required this.status,
    required this.originAccountId,
    required this.destinationAccountId,
    required this.createdAt,
    required this.idempotencyKey,
  });

  final String id;
  final String amount;
  final String status;
  final String originAccountId;
  final String destinationAccountId;
  final String createdAt;
  final String idempotencyKey;

  factory TransferResponseDto.fromJson(Map<String, dynamic> json) =>
      TransferResponseDto(
        id: json['id'] as String,
        amount: json['amount'] as String,
        status: json['status'] as String,
        originAccountId: json['origin_account_id'] as String,
        destinationAccountId: json['destination_account_id'] as String,
        createdAt: json['created_at'] as String,
        idempotencyKey: json['idempotency_key'] as String,
      );

  Transfer toDomain() => Transfer(
        id: id,
        amount: amount,
        status: status,
        originAccountId: originAccountId,
        destinationAccountId: destinationAccountId,
        createdAt: createdAt,
      );
}
