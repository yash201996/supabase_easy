import 'dart:io';
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

  // ---------------------------------------------------------------------------
  // Guard helpers — centralise try/catch to eliminate repetitive boilerplate
  // and ensure network errors are always caught.
  // ---------------------------------------------------------------------------

  /// Executes [fn] and translates any [AuthException] or network error into
  /// an [EasyException].
  static Future<R> guardAuth<R>(Future<R> Function() fn) async {
    try {
      return await fn();
    } on AuthException catch (e) {
      throw EasyException.fromAuth(e);
    } on SocketException catch (_) {
      throw const EasyException(
        'Network error — check your internet connection.',
      );
    } catch (e) {
      if (e is EasyException) rethrow;
      throw EasyException('Unexpected auth error: $e', cause: e);
    }
  }

  /// Executes [fn] and translates any [PostgrestException] or network error
  /// into an [EasyException].  [context] is typically the table name.
  static Future<R> guardDb<R>(
    Future<R> Function() fn, [
    String? context,
  ]) async {
    try {
      return await fn();
    } on PostgrestException catch (e) {
      throw EasyException.fromPostgrest(e, context);
    } on SocketException catch (_) {
      throw const EasyException(
        'Network error — check your internet connection.',
      );
    } catch (e) {
      if (e is EasyException) rethrow;
      throw EasyException('Unexpected database error: $e', cause: e);
    }
  }

  /// Executes [fn] and translates any [StorageException] or network error
  /// into an [EasyException].
  static Future<R> guardStorage<R>(Future<R> Function() fn) async {
    try {
      return await fn();
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    } on SocketException catch (_) {
      throw const EasyException(
        'Network error — check your internet connection.',
      );
    } catch (e) {
      if (e is EasyException) rethrow;
      throw EasyException('Unexpected storage error: $e', cause: e);
    }
  }
}
