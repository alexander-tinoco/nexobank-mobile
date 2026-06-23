class CardModel {
  const CardModel({
    required this.id,
    required this.cardNumber,
    required this.cardType,
    required this.status,
    required this.expiryDate,
    required this.accountId,
  });

  final String id;
  final String cardNumber;
  final String cardType;
  final String status;
  final String expiryDate;
  final String accountId;

  bool get isFrozen => status == 'frozen';

  String get maskedNumber =>
      '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
}
