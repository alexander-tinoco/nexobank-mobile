import 'package:nexobank_mobile/features/accounts/data/dtos/account_dto.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

class AccountListDto {
  const AccountListDto({required this.accounts});

  // API returns {"items": [...], "total": N}
  factory AccountListDto.fromJson(Map<String, dynamic> json) => AccountListDto(
        accounts: (json['items'] as List<dynamic>)
            .map((e) => AccountDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<AccountDto> accounts;

  List<Account> toDomain() => accounts.map((dto) => dto.toDomain()).toList();
}
