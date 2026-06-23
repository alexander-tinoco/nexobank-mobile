class Account {
  const Account({
    required this.id,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.currency,
    required this.status,
    required this.ownerId,
  });

  final String id;
  final String accountNumber;
  final String accountType;
  final String balance;
  final String currency;
  final String status;
  final String ownerId;

  bool get isActive => status == 'active';
}
