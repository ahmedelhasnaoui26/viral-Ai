import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing messages for Supabase Auth errors.
String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email before signing in. Check your inbox for the confirmation link.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists. Sign in instead.';
    }
    if (message.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return error.message;
  }

  if (error is AuthApiException) {
    return error.message;
  }

  final raw = error.toString();
  if (raw.contains('Email not confirmed')) {
    return 'Please verify your email before signing in.';
  }
  return 'Something went wrong. Please try again.';
}
