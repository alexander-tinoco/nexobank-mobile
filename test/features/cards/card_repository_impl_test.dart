import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/features/cards/data/card_repository_impl.dart';
import 'package:nexobank_mobile/features/cards/domain/models/card_model.dart';

class MockDio extends Mock implements Dio {}

final _fakeCardJson = <String, dynamic>{
  'id': 'card1',
  'card_number': '1234567890123456',
  'card_type': 'debit',
  'status': 'active',
  'expiry_date': '12/28',
  'account_id': 'acc1',
};

void main() {
  late MockDio mockDio;
  late CardRepositoryImpl sut;

  setUp(() {
    mockDio = MockDio();
    sut = CardRepositoryImpl(mockDio);
  });

  group('getCardsByAccount', () {
    test('calls GET /accounts/{id}/cards and returns list', () async {
      when(
        () => mockDio.get<List<dynamic>>('/accounts/acc1/cards'),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/accounts/acc1/cards'),
          statusCode: 200,
          data: [_fakeCardJson],
        ),
      );

      final result = await sut.getCardsByAccount('acc1');

      expect(result, isA<Success<List<CardModel>>>());
      final cards = (result as Success<List<CardModel>>).value;
      expect(cards.length, 1);
      expect(cards.first.id, 'card1');
      expect(cards.first.isFrozen, isFalse);
      verify(() => mockDio.get<List<dynamic>>('/accounts/acc1/cards')).called(1);
    });

    test('returns Failure on DioException', () async {
      when(
        () => mockDio.get<List<dynamic>>('/accounts/acc1/cards'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/accounts/acc1/cards'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await sut.getCardsByAccount('acc1');
      expect(result, isA<Failure<List<CardModel>>>());
    });
  });

  group('toggleFreeze', () {
    test('calls PATCH /cards/{id}/freeze and returns updated card', () async {
      final frozenJson = Map<String, dynamic>.from(_fakeCardJson)
        ..['status'] = 'frozen';

      when(
        () => mockDio.patch<Map<String, dynamic>>('/cards/card1/freeze'),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/cards/card1/freeze'),
          statusCode: 200,
          data: frozenJson,
        ),
      );

      final result = await sut.toggleFreeze('card1');

      expect(result, isA<Success<CardModel>>());
      final card = (result as Success<CardModel>).value;
      expect(card.isFrozen, isTrue);
      verify(() => mockDio.patch<Map<String, dynamic>>('/cards/card1/freeze'))
          .called(1);
    });
  });
}
