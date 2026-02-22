import 'package:supabase_flutter/supabase_flutter.dart';
import 'easy_exception.dart';

/// Internal client that holds the initialised [SupabaseClient] singleton.
///
/// Prefer using [SupabaseEasy] from the top-level library instead of
/// accessing this class directly.
class SupabaseEasyClient {
  static SupabaseClient? _client;

  /// Whether [initialize] has been called successfully.
  static bool get isInitialized => _client != null;

  /// Initialises Supabase and caches the resulting [SupabaseClient].
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

  /// Returns the cached [SupabaseClient].
  ///
  /// Throws [EasyException] if [initialize] has not been called yet.
  static SupabaseClient get client {
    if (_client == null) {
      throw const EasyException(
        'SupabaseEasy is not initialized. Call SupabaseEasy.initialize() first.',
      );
    }
    return _client!;
  }
}
