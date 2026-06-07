class AppEnv {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ujlvhvkshbhyttrhxwvt.supabase.co');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbHZodmtzaGJoeXR0cmh4d3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4ODMxODIsImV4cCI6MjA5NTQ1OTE4Mn0.TbZg_YJLunFIaYaItKb2lhny-B0uX4KA_7FYquzoLUg');
  static const supabaseFunctionsUrl =
      String.fromEnvironment('SUPABASE_FUNCTIONS_URL', defaultValue: 'https://ujlvhvkshbhyttrhxwvt.supabase.co/functions/v1');
  static const supabaseStorageBucket =
      String.fromEnvironment('SUPABASE_STORAGE_BUCKET', defaultValue: 'media');
  static const revenueCatAppleApiKey =
      String.fromEnvironment('REVENUECAT_APPLE_API_KEY', defaultValue: '');
  static const revenueCatGoogleApiKey =
      String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY', defaultValue: '');
  static const mixpanelToken =
      String.fromEnvironment('MIXPANEL_TOKEN', defaultValue: '7a4c9d4d1d50662c568014f117f33077');
  static const posthogApiKey =
      String.fromEnvironment('POSTHOG_API_KEY', defaultValue: 'phc_rbS3e7qJvzB8MioaQpqNMigitXMeDXjnXXZWdHfdZi9F');
  static const posthogHost =
      String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: 'https://a7eec31ff1226f33e48f354ebdfd9605@o4511463331135488.ingest.de.sentry.io/4511463339130960');
  static const appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
  static const supportEmail =
      String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'support@cinemorph.ai');
  static const supportUrl =
      String.fromEnvironment('SUPPORT_URL', defaultValue: 'mailto:support@cinemorph.ai');

  /// Public R2 bucket domain for permanent video/image URLs.
  static const publicAssetBaseUrl = String.fromEnvironment(
    'PUBLIC_ASSET_BASE_URL',
    defaultValue: 'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
