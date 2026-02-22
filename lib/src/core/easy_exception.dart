import 'package:supabase_flutter/supabase_flutter.dart';

/// A unified exception class for all errors thrown by `supabase_easy`.
///
/// Wraps the underlying Supabase/Dart exception so callers only need to
/// catch one type while still having access to the original cause.
///
/// ```dart
/// try {
///   await todoRepo.create(todo);
/// } on EasyException catch (e) {
///   print(e.message);
///   print(e.cause); // original PostgrestException / AuthException / etc.
/// }
/// ```
class EasyException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// The original exception that caused this error, if available.
  final Object? cause;

  /// Creates an [EasyException] with a human-readable [message] and an
  /// optional [cause] holding the original exception.
  const EasyException(this.message, {this.cause});

  /// Creates an [EasyException] from a [PostgrestException], optionally
  /// prefixing the message with a [context] label (e.g. the table name).
  factory EasyException.fromPostgrest(PostgrestException e, [String? context]) {
    final ctx = context != null ? '[$context] ' : '';
    return EasyException(
      '$ctx${e.message}${e.hint != null ? ' — Hint: ${e.hint}' : ''}',
      cause: e,
    );
  }

  /// Creates an [EasyException] from an [AuthException].
  factory EasyException.fromAuth(AuthException e) =>
      EasyException(e.message, cause: e);

  /// Creates an [EasyException] from a [StorageException].
  factory EasyException.fromStorage(StorageException e) =>
      EasyException(e.message, cause: e);

  @override
  String toString() => 'EasyException: $message';
}
