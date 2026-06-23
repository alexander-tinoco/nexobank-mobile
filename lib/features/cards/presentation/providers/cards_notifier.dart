import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/cards/data/card_repository_impl.dart';
import 'package:nexobank_mobile/features/cards/domain/card_repository.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';

class CardsNotifier extends FamilyAsyncNotifier<List<CardModel>, String> {
  late CardRepository _repository;

  @override
  Future<List<CardModel>> build(String accountId) async {
    _repository = ref.watch(cardRepositoryProvider);
    return _load(accountId);
  }

  Future<List<CardModel>> _load(String accountId) async {
    final result = await _repository.getCardsByAccount(accountId);
    return result.when(
      success: (List<CardModel> cards) => cards,
      failure: (error) => throw error,
    );
  }

  Future<void> toggleFreeze(String cardId) async {
    final result = await _repository.toggleFreeze(cardId);
    result.when(
      success: (CardModel updated) {
        final current = state.valueOrNull ?? <CardModel>[];
        state = AsyncData<List<CardModel>>(
          current.map((c) => c.id == cardId ? updated : c).toList(),
        );
      },
      failure: (error) => throw error,
    );
  }
}

final cardsNotifierProvider =
    AsyncNotifierProviderFamily<CardsNotifier, List<CardModel>, String>(
  CardsNotifier.new,
);
