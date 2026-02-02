library;

import 'src/core/supabase_easy_client.dart';

export 'src/core/supabase_easy_client.dart';
export 'src/auth/easy_auth.dart';
export 'src/database/easy_repository.dart';
export 'src/storage/easy_storage.dart';
export 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthState,
        Session,
        User,
        FileOptions,
        SearchOptions,
        FileObject,
        OAuthProvider;

// You can also add some convenience top-level functions or classes here if needed.
class SupabaseEasy {
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
}
