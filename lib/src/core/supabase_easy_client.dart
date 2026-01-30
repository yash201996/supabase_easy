import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEasyClient {
  static SupabaseClient? _client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: debug,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'SupabaseEasy is not initialized. Call SupabaseEasyClient.initialize() first.',
      );
    }
    return _client!;
  }
}
