sealed class AppError {
  const AppError();
}

final class InsufficientFundsError extends AppError {
  const InsufficientFundsError();
}

final class AccountNotFoundError extends AppError {
  const AccountNotFoundError();
}

final class CardFrozenError extends AppError {
  const CardFrozenError();
}

final class UnauthorizedError extends AppError {
  const UnauthorizedError();
}

final class SessionExpiredError extends AppError {
  const SessionExpiredError();
}

final class NetworkError extends AppError {
  const NetworkError(this.message);

  final String message;
}

final class UnknownError extends AppError {
  const UnknownError(this.code, this.message);

  final String code;
  final String message;
}
