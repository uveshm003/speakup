import 'package:equatable/equatable.dart';

/// Base failure for domain / use-case errors.
abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Unexpected or uncategorized errors.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}

/// Local persistence (Hive / ObjectBox / file) errors.
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

/// Parsing, serialization, or schema mismatch errors.
class FormatFailure extends Failure {
  const FormatFailure([super.message]);
}
