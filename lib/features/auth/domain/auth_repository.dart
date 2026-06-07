import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Session? get currentSession;
  Stream<AuthState> get authStateChanges;
  User? get currentUser;

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<SignUpResult> signUpWithEmailPassword({
    required String username,
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<User> updatePassword(String newPassword);
  Future<void> signOut();
}

class SignUpResult {
  const SignUpResult({
    required this.user,
    required this.emailConfirmationRequired,
  });

  final User? user;
  final bool emailConfirmationRequired;
}
