import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

class AccountDto {
  const AccountDto({
    required this.id,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.currency,
    required this.status,
    required this.ownerId,
    required this.createdAt,
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) => AccountDto(
        id: json['id'] as String,
        accountNumber: json['account_number'] as String,
        accountType: json['account_type'] as String,
        balance: json['balance'] as String,
        currency: json['currency'] as String,
        status: json['status'] as String,
        ownerId: json['owner_id'] as String,
        createdAt: json['created_at'] as String,
      );

  final String id;
  final String accountNumber;
  final String accountType;
  final String balance;
  final String currency;
  final String status;
  final String ownerId;
  final String createdAt;

  Account toDomain() => Account(
        id: id,
        accountNumber: accountNumber,
        accountType: accountType,
        balance: balance,
        currency: currency,
        status: status,
        ownerId: ownerId,
      );
}
