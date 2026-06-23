class Transfer {
  const Transfer({
    required this.id,
    required this.amount,
    required this.status,
    required this.originAccountId,
    required this.destinationAccountId,
    required this.createdAt,
  });

  final String id;
  final String amount;
  final String status;
  final String originAccountId;
  final String destinationAccountId;
  final String createdAt;

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}
