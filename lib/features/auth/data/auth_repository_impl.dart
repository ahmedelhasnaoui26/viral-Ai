import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';
import 'supabase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final SupabaseAuthDataSource _dataSource;

  @override
  Session? get currentSession => _dataSource.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _dataSource.authStateChanges;

  @override
  User? get currentUser => _dataSource.currentUser;

  @override
  Future<void> signInWithGoogle() =>
      _dataSource.signInWithOAuth(OAuthProvider.google);

  @override
  Future<void> signInWithApple() =>
      _dataSource.signInWithOAuth(OAuthProvider.apple);

  @override
  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _dataSource.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in failed. Please try again.');
    }
    if (user.emailConfirmedAt == null && user.email != null) {
      throw const AuthException('Email not confirmed');
    }
    return user;
  }

  @override
  Future<SignUpResult> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    final handle = _normalizeHandle(username);
    final response = await _dataSource.signUpWithPassword(
      email: email,
      password: password,
      metadata: {
        'display_name': username.trim(),
        'handle': handle,
      },
    );

    final user = response.user;
    final needsConfirmation = user != null && user.emailConfirmedAt == null;

    return SignUpResult(
      user: user,
      emailConfirmationRequired: needsConfirmation,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _dataSource.resetPasswordForEmail(email);

  @override
  Future<User> updatePassword(String newPassword) async {
    final response = await _dataSource.updatePassword(newPassword);
    final user = response.user;
    if (user == null) {
      throw const AuthException('Could not update password.');
    }
    return user;
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  String _normalizeHandle(String username) {
    var handle = username.trim();
    if (handle.isEmpty) return '@creator';
    if (!handle.startsWith('@')) handle = '@$handle';
    return handle;
  }
}
