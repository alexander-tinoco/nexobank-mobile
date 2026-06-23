import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';

class CardDto {
  const CardDto({
    required this.id,
    required this.cardNumber,
    required this.cardType,
    required this.status,
    required this.expiryDate,
    required this.accountId,
  });

  factory CardDto.fromJson(Map<String, dynamic> json) => CardDto(
        id: json['id'] as String,
        cardNumber: json['card_number'] as String,
        cardType: json['card_type'] as String,
        status: json['status'] as String,
        expiryDate: json['expiry_date'] as String,
        accountId: json['account_id'] as String,
      );

  final String id;
  final String cardNumber;
  final String cardType;
  final String status;
  final String expiryDate;
  final String accountId;

  CardModel toDomain() => CardModel(
        id: id,
        cardNumber: cardNumber,
        cardType: cardType,
        status: status,
        expiryDate: expiryDate,
        accountId: accountId,
      );
}
