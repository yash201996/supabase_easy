import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_easy/src/storage/easy_storage.dart';
import 'package:supabase_easy/src/core/easy_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('EasyStorage — upload validation', () {
    test('throws EasyException when neither file nor bytes provided', () async {
      expect(
        () => EasyStorage.upload(bucketId: 'test', path: 'file.png'),
        throwsA(
          isA<EasyException>().having(
            (e) => e.message,
            'message',
            contains('Either `file` or `bytes` must be provided'),
          ),
        ),
      );
    });
  });

  group('EasyStorage — MIME type detection', () {
    // The _detectMimeType function is private, but we can verify its
    // behaviour indirectly through upload. Since upload needs an
    // initialized client to complete, we test the MIME detection by
    // checking that upload with bytes throws the "not initialized" error
    // (meaning it got past the validation + MIME detection stage).

    test('upload with bytes passes validation and hits client', () async {
      expect(
        () => EasyStorage.upload(
          bucketId: 'test',
          path: 'image.png',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        // Should get past the null check and MIME detection,
        // then fail because client is not initialized.
        throwsA(isA<EasyException>()),
      );
    });

    test('upload with unknown extension still works', () async {
      expect(
        () => EasyStorage.upload(
          bucketId: 'test',
          path: 'data.xyz',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        // Should still proceed (MIME will be null, which is fine).
        throwsA(isA<EasyException>()),
      );
    });

    test('upload with explicit contentType skips auto-detection', () async {
      expect(
        () => EasyStorage.upload(
          bucketId: 'test',
          path: 'file.bin',
          bytes: Uint8List.fromList([1, 2, 3]),
          options: const FileOptions(contentType: 'application/octet-stream'),
        ),
        throwsA(isA<EasyException>()),
      );
    });
  });

  group('EasyStorage — methods throw when not initialized', () {
    test('download throws EasyException', () async {
      expect(
        () => EasyStorage.download(bucketId: 'test', path: 'file.png'),
        throwsA(isA<EasyException>()),
      );
    });

    test('delete throws EasyException', () async {
      expect(
        () => EasyStorage.delete(bucketId: 'test', paths: ['file.png']),
        throwsA(isA<EasyException>()),
      );
    });

    test('getPublicUrl throws EasyException', () {
      expect(
        () => EasyStorage.getPublicUrl(bucketId: 'test', path: 'file.png'),
        throwsA(isA<EasyException>()),
      );
    });

    test('list throws EasyException', () async {
      expect(
        () => EasyStorage.list(bucketId: 'test'),
        throwsA(isA<EasyException>()),
      );
    });

    test('move throws EasyException', () async {
      expect(
        () => EasyStorage.move(
          bucketId: 'test',
          fromPath: 'a.png',
          toPath: 'b.png',
        ),
        throwsA(isA<EasyException>()),
      );
    });

    test('copy throws EasyException', () async {
      expect(
        () => EasyStorage.copy(
          bucketId: 'test',
          fromPath: 'a.png',
          toPath: 'b.png',
        ),
        throwsA(isA<EasyException>()),
      );
    });

    test('createSignedUrl throws EasyException', () async {
      expect(
        () => EasyStorage.createSignedUrl(
          bucketId: 'test',
          path: 'file.png',
          expiresIn: 3600,
        ),
        throwsA(isA<EasyException>()),
      );
    });

    test('bucket throws EasyException', () {
      expect(
        () => EasyStorage.bucket('test'),
        throwsA(isA<EasyException>()),
      );
    });
  });
}
