import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_easy/supabase_easy.dart';

void main() {
  group('EasyException', () {
    test('constructor stores message and cause', () {
      final cause = Exception('original');
      final e = EasyException('Something failed', cause: cause);

      expect(e.message, 'Something failed');
      expect(e.cause, cause);
    });

    test('const constructor works without cause', () {
      const e = EasyException('no cause');
      expect(e.message, 'no cause');
      expect(e.cause, isNull);
    });

    test('toString returns formatted message', () {
      const e = EasyException('test message');
      expect(e.toString(), 'EasyException: test message');
    });

    test('implements Exception', () {
      const e = EasyException('test');
      expect(e, isA<Exception>());
    });
  });

  group('EasyException.fromPostgrest', () {
    test('wraps message and cause', () {
      final pgError = PostgrestException(message: 'duplicate key');
      final e = EasyException.fromPostgrest(pgError);

      expect(e.message, 'duplicate key');
      expect(e.cause, pgError);
    });

    test('includes context prefix when provided', () {
      final pgError = PostgrestException(message: 'duplicate key');
      final e = EasyException.fromPostgrest(pgError, 'todos');

      expect(e.message, startsWith('[todos] '));
      expect(e.message, contains('duplicate key'));
    });

    test('includes hint when available', () {
      final pgError = PostgrestException(
        message: 'insert failed',
        hint: 'Check RLS policies',
      );
      final e = EasyException.fromPostgrest(pgError);

      expect(e.message, contains('Hint: Check RLS policies'));
    });

    test('omits hint when null', () {
      final pgError = PostgrestException(message: 'error');
      final e = EasyException.fromPostgrest(pgError);

      expect(e.message, isNot(contains('Hint')));
    });

    test('includes both context and hint', () {
      final pgError = PostgrestException(
        message: 'failed',
        hint: 'try again',
      );
      final e = EasyException.fromPostgrest(pgError, 'users');

      expect(e.message, '[users] failed — Hint: try again');
    });
  });

  group('EasyException.fromAuth', () {
    test('wraps AuthException message and cause', () {
      final authError = AuthException('Invalid credentials');
      final e = EasyException.fromAuth(authError);

      expect(e.message, 'Invalid credentials');
      expect(e.cause, authError);
    });
  });

  group('EasyException.fromStorage', () {
    test('wraps StorageException message and cause', () {
      final storageError = StorageException('Bucket not found');
      final e = EasyException.fromStorage(storageError);

      expect(e.message, 'Bucket not found');
      expect(e.cause, storageError);
    });
  });

  group('EasyException.guardAuth', () {
    test('returns value on success', () async {
      final result = await EasyException.guardAuth(() async => 42);
      expect(result, 42);
    });

    test('wraps AuthException into EasyException', () async {
      expect(
        () => EasyException.guardAuth(
          () async => throw AuthException('bad creds'),
        ),
        throwsA(
          isA<EasyException>()
              .having((e) => e.message, 'message', 'bad creds')
              .having((e) => e.cause, 'cause', isA<AuthException>()),
        ),
      );
    });

    test('wraps SocketException into network EasyException', () async {
      expect(
        () => EasyException.guardAuth(
          () async =>
              throw const SocketException('Connection refused'),
        ),
        throwsA(
          isA<EasyException>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ),
      );
    });

    test('rethrows EasyException without wrapping', () async {
      const original = EasyException('already wrapped');
      expect(
        () => EasyException.guardAuth(() async => throw original),
        throwsA(same(original)),
      );
    });

    test('wraps unknown exceptions with cause', () async {
      expect(
        () => EasyException.guardAuth(
          () async => throw StateError('unexpected'),
        ),
        throwsA(
          isA<EasyException>()
              .having(
                (e) => e.message,
                'message',
                contains('Unexpected auth error'),
              )
              .having((e) => e.cause, 'cause', isA<StateError>()),
        ),
      );
    });
  });

  group('EasyException.guardDb', () {
    test('returns value on success', () async {
      final result = await EasyException.guardDb(() async => 'ok');
      expect(result, 'ok');
    });

    test('wraps PostgrestException into EasyException', () async {
      expect(
        () => EasyException.guardDb(
          () async =>
              throw PostgrestException(message: 'constraint violation'),
          'todos',
        ),
        throwsA(
          isA<EasyException>()
              .having(
                (e) => e.message,
                'message',
                contains('[todos] constraint violation'),
              )
              .having((e) => e.cause, 'cause', isA<PostgrestException>()),
        ),
      );
    });

    test('wraps SocketException into network EasyException', () async {
      expect(
        () => EasyException.guardDb(
          () async =>
              throw const SocketException('No route to host'),
        ),
        throwsA(
          isA<EasyException>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ),
      );
    });

    test('rethrows EasyException without wrapping', () async {
      const original = EasyException('already wrapped');
      expect(
        () => EasyException.guardDb(() async => throw original),
        throwsA(same(original)),
      );
    });

    test('wraps unknown exceptions with cause', () async {
      expect(
        () => EasyException.guardDb(
          () async => throw FormatException('bad data'),
        ),
        throwsA(
          isA<EasyException>()
              .having(
                (e) => e.message,
                'message',
                contains('Unexpected database error'),
              )
              .having((e) => e.cause, 'cause', isA<FormatException>()),
        ),
      );
    });

    test('works without context parameter', () async {
      expect(
        () => EasyException.guardDb(
          () async =>
              throw PostgrestException(message: 'error'),
        ),
        throwsA(
          isA<EasyException>().having(
            (e) => e.message,
            'message',
            isNot(contains('[')),
          ),
        ),
      );
    });
  });

  group('EasyException.guardStorage', () {
    test('returns value on success', () async {
      final result = await EasyException.guardStorage(() async => [1, 2, 3]);
      expect(result, [1, 2, 3]);
    });

    test('wraps StorageException into EasyException', () async {
      expect(
        () => EasyException.guardStorage(
          () async => throw StorageException('File too large'),
        ),
        throwsA(
          isA<EasyException>()
              .having(
                (e) => e.message,
                'message',
                'File too large',
              )
              .having((e) => e.cause, 'cause', isA<StorageException>()),
        ),
      );
    });

    test('wraps SocketException into network EasyException', () async {
      expect(
        () => EasyException.guardStorage(
          () async =>
              throw const SocketException('Connection reset'),
        ),
        throwsA(
          isA<EasyException>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ),
      );
    });

    test('rethrows EasyException without wrapping', () async {
      const original = EasyException('already wrapped');
      expect(
        () => EasyException.guardStorage(() async => throw original),
        throwsA(same(original)),
      );
    });

    test('wraps unknown exceptions with cause', () async {
      expect(
        () => EasyException.guardStorage(
          () async => throw ArgumentError('bad arg'),
        ),
        throwsA(
          isA<EasyException>()
              .having(
                (e) => e.message,
                'message',
                contains('Unexpected storage error'),
              )
              .having((e) => e.cause, 'cause', isA<ArgumentError>()),
        ),
      );
    });
  });
}
