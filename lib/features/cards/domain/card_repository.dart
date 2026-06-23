import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';

abstract interface class CardRepository {
  Future<Result<List<CardModel>>> getCardsByAccount(String accountId);
  Future<Result<CardModel>> toggleFreeze(String cardId);
}
