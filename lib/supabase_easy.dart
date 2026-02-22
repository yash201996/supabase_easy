import 'src/core/supabase_easy_client.dart';

export 'src/core/supabase_easy_client.dart';
export 'src/core/easy_exception.dart';
export 'src/auth/easy_auth.dart';
export 'src/database/easy_repository.dart';
export 'src/storage/easy_storage.dart';

// Re-export the most commonly needed Supabase types so consumers rarely need
// to import supabase_flutter directly.
export 'package:supabase_flutter/supabase_flutter.dart'
    show
        // Auth types
        AuthState,
        AuthResponse,
        AuthException,
        OAuthProvider,
        OtpType,
        Session,
        User,
        UserResponse,
        // Database types
        PostgrestException,
        CountOption,
        // Storage types
        FileOptions,
        SearchOptions,
        FileObject,
        StorageException,
        TransformOptions;

/// Top-level entry point for `supabase_easy`.
///
/// Call [SupabaseEasy.initialize] once in `main()` before using any other API.
class SupabaseEasy {
  // Private constructor – this class is not meant to be instantiated.
  SupabaseEasy._();

  /// Initialises Supabase and the `supabase_easy` client.
  ///
  /// Must be called before any other `supabase_easy` API.
  ///
  /// ```dart
  /// await SupabaseEasy.initialize(
  ///   url: const String.fromEnvironment('SUPABASE_URL'),
  ///   anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  /// );
  /// ```
  static Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    await SupabaseEasyClient.initialize(
      url: url,
      anonKey: anonKey,
      debug: debug,
    );
  }

  /// Whether [initialize] has been called successfully.
  static bool get isInitialized => SupabaseEasyClient.isInitialized;
}

