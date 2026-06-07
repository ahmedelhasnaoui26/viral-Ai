import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/auth_redirect_config.dart';

class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this._supabase);

  final SupabaseClient _supabase;

  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    final redirectTo = _mobileRedirectUrl;
    if (redirectTo == null) {
      throw UnsupportedError('OAuth sign-in is only supported on iOS and Android.');
    }

    await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) {
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
      emailRedirectTo: _emailRedirectUrl,
    );
  }

  Future<void> resetPasswordForEmail(String email) {
    return _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _passwordRecoveryRedirectUrl,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _supabase.auth.signOut();

  Future<AuthResponse> signInAnonymously() => _supabase.auth.signInAnonymously();

  static String? get _mobileRedirectUrl {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isAndroid) {
      return AuthRedirectConfig.oauthRedirectUrl;
    }
    return null;
  }

  static String? get _emailRedirectUrl {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isAndroid) {
      return AuthRedirectConfig.emailAuthRedirectUrl;
    }
    return null;
  }

  static String? get _passwordRecoveryRedirectUrl {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isAndroid) {
      return AuthRedirectConfig.passwordRecoveryRedirectUrl;
    }
    return null;
  }
}
