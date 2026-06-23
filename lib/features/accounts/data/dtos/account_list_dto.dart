import 'package:nexobank_mobile/features/accounts/data/dtos/account_dto.dart';
import 'package:nexobank_mobile/features/accounts/domain/models/account.dart';

class AccountListDto {
  const AccountListDto({required this.accounts});

  factory AccountListDto.fromJson(List<dynamic> json) => AccountListDto(
        accounts: json
            .map((e) => AccountDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<AccountDto> accounts;

  List<Account> toDomain() => accounts.map((dto) => dto.toDomain()).toList();
}
