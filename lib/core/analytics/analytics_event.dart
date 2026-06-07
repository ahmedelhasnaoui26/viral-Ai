class AnalyticsEvent {
  const AnalyticsEvent(this.name, {this.properties = const {}});

  final String name;
  final Map<String, Object?> properties;
}

class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const signInSuccess = 'sign_in_success';
  static const generationStarted = 'generation_started';
  static const generationCompleted = 'generation_completed';
  static const generationFailed = 'generation_failed';
  static const paywallViewed = 'paywall_viewed';
  static const subscriptionStarted = 'subscription_started';
  static const shareTapped = 'share_tapped';
  static const exportCompleted = 'export_completed';
  static const retentionDay1 = 'retention_day_1';
  static const retentionDay7 = 'retention_day_7';
  static const guestModeEntered = 'guest_mode_entered';
  static const guestGenerateAttempt = 'guest_generate_attempt';
  static const authModalOpened = 'auth_modal_opened';
  static const guestConversionStarted = 'guest_conversion_started';
  static const guestConversionCompleted = 'guest_conversion_completed';
}
