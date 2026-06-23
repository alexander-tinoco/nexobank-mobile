class Transaction {
  const Transaction({
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

  bool get isCredit => type == 'credit';
  bool get isCompleted => status == 'completed';
}
