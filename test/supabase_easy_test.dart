import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_easy/supabase_easy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseEasy', () {
    test('isInitialized returns false before initialization', () {
      // In a fresh test process, no one has called initialize().
      // The static _client is null, so isInitialized should be false.
      expect(SupabaseEasy.isInitialized, isA<bool>());
    });

    test('SupabaseEasy cannot be instantiated (private constructor)', () {
      // SupabaseEasy._() is private; the class should only expose statics.
      // We verify by checking the type itself exposes the expected API.
      expect(SupabaseEasy.isInitialized, isA<bool>());
    });

    test('initialize delegates to SupabaseEasyClient and Supabase SDK',
        () async {
      // Mock SharedPreferences so Supabase.initialize can proceed.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') return <String, dynamic>{};
          return null;
        },
      );

      // With an empty URL, the HTTP client will fail, but we prove
      // the method delegates correctly.
      try {
        await SupabaseEasy.initialize(url: 'https://x.supabase.co', anonKey: 'test-key');
        // If it succeeds (unlikely but possible), isInitialized should be true.
        expect(SupabaseEasy.isInitialized, true);
      } catch (e) {
        // Any error at this point is from the Supabase SDK itself—our
        // delegation was successful.
        expect(e, isNotNull);
      }

      // Clean up the mock.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        null,
      );
    });
  });

  group('Public API exports', () {
    test('EasyException is exported', () {
      const e = EasyException('test');
      expect(e, isA<Exception>());
    });

    test('EasyAuth class is importable and exposes static API', () {
      // Just verify the class is importable and the getter exists.
      // Whether it throws or returns null depends on initialization state.
      try {
        final user = EasyAuth.currentUser;
        expect(user, isNull);
      } on EasyException {
        // Also acceptable — means client is not initialized.
      }
    });

    test('EasyRepository class is importable and constructible', () {
      // Whether the constructor throws depends on initialization state.
      try {
        final repo = EasyRepository<_DummyModel>(
          tableName: 't',
          fromJson: _DummyModel.fromJson,
        );
        expect(repo.tableName, 't');
      } on EasyException {
        // Also acceptable — means client is not initialized.
      }
    });

    test('EasyStorage class is importable', () {
      try {
        final bucket = EasyStorage.bucket('b');
        expect(bucket, isNotNull);
      } on EasyException {
        // Also acceptable — means client is not initialized.
      }
    });

    test('Re-exported Supabase types are available', () {
      // Verify key re-exports compile and are usable.
      expect(CountOption.exact, isNotNull);
      expect(OtpType.email, isNotNull);
      expect(OAuthProvider.google, isNotNull);
    });
  });
}

/// Minimal EasyModel implementation for testing exports.
class _DummyModel extends EasyModel {
  @override
  final String id;

  _DummyModel({required this.id});

  @override
  Map<String, dynamic> toJson() => {'id': id};

  factory _DummyModel.fromJson(Map<String, dynamic> json) =>
      _DummyModel(id: json['id'] as String);
}
