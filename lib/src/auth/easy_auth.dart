import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';

class EasyAuth {
  static GoTrueClient get _auth => SupabaseEasyClient.client.auth;

  static User? get currentUser => _auth.currentUser;

  static Session? get currentSession => _auth.currentSession;

  static Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }
}
