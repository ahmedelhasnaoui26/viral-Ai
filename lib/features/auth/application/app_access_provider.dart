import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_access_state.dart';
import 'auth_providers.dart';
import 'guest_mode_provider.dart';

final appAccessStateProvider = Provider<AppAccessState>((ref) {
  final authUser = ref.watch(authSessionProvider).value;
  if (authUser != null) {
    return AuthUserState(authUser);
  }

  final guestState = ref.watch(guestModeProvider);
  if (guestState.isGuest) {
    return const GuestUserState();
  }

  return const UnauthenticatedUserState();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(appAccessStateProvider).isAuthenticated;
});

final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(appAccessStateProvider).isGuest;
});

final canAccessProtectedFeaturesProvider = Provider<bool>((ref) {
  return ref.watch(appAccessStateProvider).canAccessProtectedFeatures;
});

/// Convenience when only the Supabase user is needed.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authSessionProvider).value;
});
