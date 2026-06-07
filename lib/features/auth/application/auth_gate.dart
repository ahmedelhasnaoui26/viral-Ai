import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/di/providers.dart';
import '../domain/auth_gated_action.dart';
import '../presentation/widgets/auth_required_modal.dart';
import 'app_access_provider.dart';
import 'auth_providers.dart';
import 'guest_mode_provider.dart';

/// Returns `true` if the user may proceed with a protected action.
Future<bool> requireAuthentication(
  BuildContext context,
  WidgetRef ref, {
  required AuthGatedAction action,
}) async {
  final access = ref.read(appAccessStateProvider);
  if (access.canAccessProtectedFeatures) {
    return true;
  }

  final analytics = ref.read(analyticsServiceProvider).asData?.value;
  await analytics?.track(
    AnalyticsEvent(
      AnalyticsEvents.authModalOpened,
      properties: {'action': action.name},
    ),
  );

  if (action == AuthGatedAction.generateVideo ||
      action == AuthGatedAction.uploadImage) {
    await analytics?.track(const AnalyticsEvent(AnalyticsEvents.guestGenerateAttempt));
  }

  if (!context.mounted) return false;

  final signedIn = await showAuthRequiredModal(
    context,
    action: action,
    ref: ref,
  );

  return signedIn;
}

/// Call after a successful sign-in that started from guest mode.
Future<void> onGuestConversionCompleted(WidgetRef ref) async {
  await ref.read(guestModeProvider.notifier).clearGuestMode();
  final analytics = ref.read(analyticsServiceProvider).asData?.value;
  await analytics?.track(const AnalyticsEvent(AnalyticsEvents.guestConversionCompleted));
}

/// Call when user taps a sign-in option from the auth modal.
Future<void> trackGuestConversionStarted(WidgetRef ref, String method) async {
  final analytics = ref.read(analyticsServiceProvider).asData?.value;
  await analytics?.track(
    AnalyticsEvent(
      AnalyticsEvents.guestConversionStarted,
      properties: {'method': method},
    ),
  );
}

/// Signs in and clears guest mode on success.
Future<bool> signInFromGate(
  WidgetRef ref, {
  required Future<void> Function() signIn,
  required String method,
}) async {
  await trackGuestConversionStarted(ref, method);
  try {
    await signIn();
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await onGuestConversionCompleted(ref);
      return true;
    }
  } catch (_) {
  }
  return false;
}
