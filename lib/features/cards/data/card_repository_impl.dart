import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/features/cards/data/dtos/card_dto.dart';
import 'package:nexobank_mobile/features/cards/domain/card_repository.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';

class CardRepositoryImpl implements CardRepository {
  const CardRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<CardModel>>> getCardsByAccount(String accountId) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/accounts/$accountId/cards');
      final cards = (response.data!)
          .map((e) => CardDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
      return Success(cards);
    } on DioException catch (e) {
      return Failure(
        e.error is AppError
            ? e.error as AppError
            : const NetworkError('Error desconocido'),
      );
    }
  }

  @override
  Future<Result<CardModel>> toggleFreeze(String cardId) async {
    try {
      final response =
          await _dio.patch<Map<String, dynamic>>('/cards/$cardId/freeze');
      final card = CardDto.fromJson(response.data!).toDomain();
      return Success(card);
    } on DioException catch (e) {
      return Failure(
        e.error is AppError
            ? e.error as AppError
            : const NetworkError('Error desconocido'),
      );
    }
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return CardRepositoryImpl(dio);
});
