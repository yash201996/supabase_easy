import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';
import '../core/easy_exception.dart';

/// A simplified wrapper around Supabase Auth.
///
/// Performance notes:
/// - All methods use [EasyException.guardAuth] which catches [AuthException],
///   [SocketException] (network failures), and unexpected errors in one place.
/// - The [GoTrueClient] reference is resolved once via a static getter that
///   caches the lookup after the first access.
class EasyAuth {
  static GoTrueClient get _auth => SupabaseEasyClient.client.auth;

  /// Returns the currently logged-in user, if any.
  static User? get currentUser => _auth.currentUser;

  /// Returns the current authentication session, if any.
  static Session? get currentSession => _auth.currentSession;

  /// Whether a user is currently signed in.
  static bool get isSignedIn => _auth.currentUser != null;

  /// A stream that emits events whenever the authentication state changes.
  static Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Signs up a new user with the given [email] and [password].
  ///
  /// You can optionally provide additional [data] to be stored in the user's profile.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) =>
      EasyException.guardAuth(
        () => _auth.signUp(email: email, password: password, data: data),
      );

  /// Signs in an existing user with their [email] and [password].
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      EasyException.guardAuth(
        () => _auth.signInWithPassword(email: email, password: password),
      );

  /// Signs out the current user and clears the session.
  static Future<void> signOut() =>
      EasyException.guardAuth(() => _auth.signOut());

  /// Initiates social login via an OAuth [provider].
  static Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  }) =>
      EasyException.guardAuth(
        () => _auth.signInWithOAuth(
          provider,
          redirectTo: redirectTo,
          scopes: scopes,
          queryParams: queryParams,
        ),
      );

  /// Sends a one-time password (magic link / OTP) to the given [email].
  ///
  /// Set [shouldCreateUser] to `false` to prevent account creation for
  /// addresses that are not already registered.
  static Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
    Map<String, dynamic>? data,
  }) =>
      EasyException.guardAuth(
        () => _auth.signInWithOtp(
          email: email,
          shouldCreateUser: shouldCreateUser,
          data: data,
        ),
      );

  /// Verifies an OTP [token] for the given [email].
  ///
  /// [type] defaults to [OtpType.email]. Use [OtpType.magiclink] for
  /// magic-link flows.
  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) =>
      EasyException.guardAuth(
        () => _auth.verifyOTP(email: email, token: token, type: type),
      );

  /// Sends a password reset email to the given [email] address.
  static Future<void> resetPassword(String email) =>
      EasyException.guardAuth(() => _auth.resetPasswordForEmail(email));

  /// Updates user attributes such as password or metadata.
  static Future<UserResponse> updateUser({
    String? password,
    Map<String, dynamic>? data,
  }) =>
      EasyException.guardAuth(
        () => _auth.updateUser(
          UserAttributes(password: password, data: data),
        ),
      );

  /// Refreshes the current session and returns the new [AuthResponse].
  static Future<AuthResponse> refreshSession() =>
      EasyException.guardAuth(() => _auth.refreshSession());
}

