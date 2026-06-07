/// OAuth deep-link configuration for Supabase Auth on mobile.
///
/// Must match:
/// - iOS `CFBundleURLSchemes` / Android intent-filter scheme
/// - Supabase Dashboard → Authentication → URL Configuration → Redirect URLs
abstract final class AuthRedirectConfig {
  static const bundleId = 'com.viralai.cinemorph';

  /// Production mobile OAuth callback used by Google & Apple sign-in.
  static const oauthRedirectUrl = '$bundleId://login-callback';

  /// Host segment of [oauthRedirectUrl] (used for Android intent filters).
  static const oauthRedirectHost = 'login-callback';

  /// Email confirmation & password recovery deep link.
  static const emailAuthRedirectUrl = '$bundleId://email-auth';

  static const emailAuthRedirectHost = 'email-auth';

  static const passwordRecoveryRedirectUrl = '$bundleId://reset-password';

  static const passwordRecoveryRedirectHost = 'reset-password';

  /// True when [uri] is the Supabase OAuth PKCE / implicit callback.
  static bool isOAuthCallback(Uri uri) {
    if (uri.scheme != bundleId) return false;
    if (uri.host != oauthRedirectHost) return false;
    return uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('error_description');
  }

  /// GoRouter may receive the full deep link string as the location.
  static bool isOAuthCallbackLocation(String location) {
    if (location.startsWith('$bundleId://')) {
      return isOAuthCallback(Uri.parse(location));
    }
    return false;
  }

  static bool isPasswordRecoveryCallback(Uri uri) {
    if (uri.scheme != bundleId) return false;
    if (uri.host == passwordRecoveryRedirectHost) return true;
    if (uri.queryParameters['type'] == 'recovery') return true;
    return false;
  }

  static bool isEmailAuthCallback(Uri uri) {
    if (uri.scheme != bundleId) return false;
    return uri.host == emailAuthRedirectHost;
  }

  static bool isAuthDeepLink(Uri uri) {
    return isOAuthCallback(uri) ||
        isPasswordRecoveryCallback(uri) ||
        isEmailAuthCallback(uri);
  }

  static bool isAuthDeepLinkLocation(String location) {
    if (!location.startsWith('$bundleId://')) return false;
    return isAuthDeepLink(Uri.parse(location));
  }
}
