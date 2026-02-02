import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';

/// A simplified wrapper around Supabase Auth.
class EasyAuth {
  static GoTrueClient get _auth => SupabaseEasyClient.client.auth;

  /// Returns the currently logged-in user, if any.
  static User? get currentUser => _auth.currentUser;

  /// Returns the current authentication session, if any.
  static Session? get currentSession => _auth.currentSession;

  /// A stream that emits events whenever the authentication state changes.
  static Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Signs up a new user with the given [email] and [password].
  ///
  /// You can optionally provide additional [data] to be stored in the user's profile.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _auth.signUp(email: email, password: password, data: data);
  }

  /// Signs in an existing user with their [email] and [password].
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  /// Signs out the current user and clears the session.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Initiates social login via OAuth provider.
  static Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  }) async {
    return await _auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
      scopes: scopes,
      queryParams: queryParams,
    );
  }

  /// Sends a password reset email to the given [email] address.
  static Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  /// Updates user attributes such as password or metadata.
  static Future<UserResponse> updateUser({
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await _auth.updateUser(
      UserAttributes(password: password, data: data),
    );
  }

  /// Refreshes the current session.
  static Future<AuthResponse> refreshSession() async {
    return await _auth.refreshSession();
  }
}
