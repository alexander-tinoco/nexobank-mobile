import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/transfers/data/dtos/transfer_request_dto.dart';
import 'package:nexobank_mobile/features/transfers/data/transfer_repository_impl.dart';
import 'package:nexobank_mobile/features/transfers/domain/models/transfer.dart';
import 'package:nexobank_mobile/features/transfers/domain/transfer_repository.dart';

sealed class TransferState {
  const TransferState();
}

class TransferIdle extends TransferState {
  const TransferIdle();
}

class TransferLoading extends TransferState {
  const TransferLoading();
}

class TransferSuccess extends TransferState {
  const TransferSuccess(this.transfer);

  final Transfer transfer;
}

class TransferFailure extends TransferState {
  const TransferFailure(this.error);

  final AppError error;
}

class TransferNotifier extends Notifier<TransferState> {
  @override
  TransferState build() => const TransferIdle();

  TransferRepository get _repo => ref.read(transferRepositoryProvider);

  Future<void> execute(TransferRequestDto dto) async {
    // Guard against double submit
    if (state is TransferLoading) return;

    state = const TransferLoading();
    final result = await _repo.executeTransfer(dto);
    state = switch (result) {
      Success<Transfer>(value: final t) => TransferSuccess(t),
      Failure<Transfer>(error: final e) => TransferFailure(e),
    };
  }

  void reset() => state = const TransferIdle();
}

final transferNotifierProvider =
    NotifierProvider<TransferNotifier, TransferState>(TransferNotifier.new);
