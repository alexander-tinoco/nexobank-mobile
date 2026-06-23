import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_request_dto.dart';
import 'package:nexobank_mobile/features/transfers/domain/models/transfer.dart';

abstract interface class TransferRepository {
  Future<Result<Transfer>> executeTransfer(TransferRequestDto dto);
}
