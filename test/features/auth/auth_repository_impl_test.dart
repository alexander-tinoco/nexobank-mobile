import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexobank_mobile/core/errors/app_error.dart';
import 'package:nexobank_mobile/core/errors/result.dart';
import 'package:nexobank_mobile/core/network/dio_client.dart';
import 'package:nexobank_mobile/core/storage/secure_storage.dart';
import 'package:nexobank_mobile/features/auth/data/auth_repository_impl.dart';

class MockDio extends Mock implements Dio {}

class MockDioClient extends Mock implements DioClient {
  MockDioClient(this._mockDio);
  final MockDio _mockDio;

  @override
  Dio get dio => _mockDio;
}

class MockSecureStorage extends Mock implements SecureStorage {}

// API now returns only tokens — user data fetched via GET /users/me
const _tokenResponseJson = <String, dynamic>{
  'access_token': 'access_abc',
  'refresh_token': 'refresh_xyz',
};

const _meResponseJson = <String, dynamic>{
  'id': 'user-1',
  'full_name': 'Jane Doe',
  'email': 'jane@test.com',
};

void main() {
  late MockDio mockDio;
  late MockDioClient mockDioClient;
  late MockSecureStorage mockStorage;
  late AuthRepositoryImpl sut;

  setUp(() {
    mockDio = MockDio();
    mockDioClient = MockDioClient(mockDio);
    mockStorage = MockSecureStorage();
    sut = AuthRepositoryImpl(
      dioClient: mockDioClient,
      secureStorage: mockStorage,
    );
    registerFallbackValue(RequestOptions(path: ''));
  });

  void stubSaveTokens() {
    when(
      () => mockStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockStorage.saveUserData(any())).thenAnswer((_) async {});
  }

  void stubMeEndpoint() {
    when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/users/me'),
        statusCode: 200,
        data: _meResponseJson,
      ),
    );
  }

  group('login', () {
    test('exitoso: guarda tokens, llama /users/me y devuelve AuthUser', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: _tokenResponseJson,
        ),
      );
      stubMeEndpoint();
      stubSaveTokens();

      final result = await sut.login(
        email: 'jane@test.com',
        password: 'secret123',
      );

      expect(result, isA<Success<dynamic>>());
      final user = (result as Success).value;
      expect(user.id, 'user-1');
      expect(user.name, 'Jane Doe');
      expect(user.email, 'jane@test.com');

      verify(
        () => mockStorage.saveTokens(
          accessToken: 'access_abc',
          refreshToken: 'refresh_xyz',
        ),
      ).called(1);
      verify(() => mockStorage.saveUserData(any())).called(1);
      verify(() => mockDio.get<Map<String, dynamic>>(any())).called(1);
    });

    test('POST falla con DioException → devuelve Failure con AppError', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          error: const UnauthorizedError(),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await sut.login(email: 'bad@test.com', password: 'wrong');

      expect(result, isA<Failure<dynamic>>());
      expect((result as Failure).error, isA<UnauthorizedError>());
    });
  });

  group('register', () {
    test('exitoso: guarda tokens, llama /users/me y devuelve AuthUser', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 201,
          data: _tokenResponseJson,
        ),
      );
      stubMeEndpoint();
      stubSaveTokens();

      final result = await sut.register(
        name: 'Jane Doe',
        email: 'jane@test.com',
        password: 'secret123',
      );

      expect(result, isA<Success<dynamic>>());
      final user = (result as Success).value;
      expect(user.id, 'user-1');
      expect(user.email, 'jane@test.com');
    });
  });

  group('logout', () {
    test('llama /auth/logout y limpia tokens', () async {
      when(
        () => mockDio.post<void>(any()),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/logout'),
          statusCode: 204,
        ),
      );
      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      final result = await sut.logout();

      expect(result, isA<Success<void>>());
      verify(() => mockStorage.clearTokens()).called(1);
    });

    test('incluso si el servidor falla, limpia los tokens locales', () async {
      when(
        () => mockDio.post<void>(any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/logout'),
          error: const NetworkError('offline'),
          type: DioExceptionType.connectionError,
        ),
      );
      when(() => mockStorage.clearTokens()).thenAnswer((_) async {});

      final result = await sut.logout();

      expect(result, isA<Failure<void>>());
      verify(() => mockStorage.clearTokens()).called(1);
    });
  });
}
