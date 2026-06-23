class TransferRequestDto {
  const TransferRequestDto({
    required this.amount,
    required this.destinationAccountId,
    required this.idempotencyKey,
    this.description,
  });

  final String amount;
  final String destinationAccountId;
  final String idempotencyKey;
  final String? description;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'destination_account_id': destinationAccountId,
        'idempotency_key': idempotencyKey,
        if (description != null) 'description': description,
      };
}
