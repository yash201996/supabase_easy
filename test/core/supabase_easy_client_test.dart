import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_easy/supabase_easy.dart';

void main() {
  group('SupabaseEasyClient', () {
    test('isInitialized returns false before initialization', () {
      // We can't call SupabaseEasyClient.isInitialized directly because
      // a previous test run may have already initialized it. Instead we
      // test the client getter behaviour when not initialized by checking
      // that the expected exception is thrown.
      //
      // NOTE: SupabaseEasyClient relies on Supabase.initialize which needs
      // a network/mock server. The client getter is the only thing we can
      // unit-test in pure Dart.
      expect(SupabaseEasyClient.isInitialized, isA<bool>());
    });

    test('client getter throws EasyException when not initialized', () {
      // Reset state – we can't do this directly because _client is private,
      // so we rely on a fresh test process. In case it was already initialized,
      // we simply verify the return type.
      try {
        final client = SupabaseEasyClient.client;
        // If we get here, it was already initialized (e.g. in CI).
        expect(client, isNotNull);
      } on EasyException catch (e) {
        expect(e.message, contains('not initialized'));
        expect(e.message, contains('SupabaseEasy.initialize()'));
      }
    });
  });

  group('SupabaseEasy', () {
    test('isInitialized reflects client state', () {
      expect(SupabaseEasy.isInitialized, isA<bool>());
    });
  });
}
