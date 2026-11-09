import 'package:fpdart/fpdart.dart';

sealed class AppFailure {
  const AppFailure();
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.cause]);
  final Object? cause;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class CacheFailure extends AppFailure {
  const CacheFailure();
}

final class BackupNotImplementedFailure extends AppFailure {
  const BackupNotImplementedFailure();
}

final class GoogleDriveFailure extends AppFailure {
  const GoogleDriveFailure([this.message]);
  final String? message;
}

final class AnilistAuthFailure extends AppFailure {
  const AnilistAuthFailure([this.message]);
  final String? message;
}

final class BackupParseFailure extends AppFailure {
  const BackupParseFailure();
}

typedef AppResult<T> = Either<AppFailure, T>;
