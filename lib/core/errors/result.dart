import 'package:nexobank_mobile/core/errors/app_error.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Failure<T>(error: final e) => e,
        Success<T>() => null,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      switch (this) {
        Success<T>(value: final v) => success(v),
        Failure<T>(error: final e) => failure(e),
      };
}
