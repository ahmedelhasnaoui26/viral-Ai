import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents how the user is accessing the app.
@immutable
sealed class AppAccessState {
  const AppAccessState();

  bool get isAuthenticated => this is AuthUserState;
  bool get isGuest => this is GuestUserState;
  bool get canAccessProtectedFeatures => isAuthenticated;
}

/// Signed-in user with a backend account.
class AuthUserState extends AppAccessState {
  const AuthUserState(this.user);

  final User user;

  String get userId => user.id;
}

/// Guest exploring the app without an account.
class GuestUserState extends AppAccessState {
  const GuestUserState();
}

/// No session yet — first launch before entering guest or signing in.
class UnauthenticatedUserState extends AppAccessState {
  const UnauthenticatedUserState();
}
