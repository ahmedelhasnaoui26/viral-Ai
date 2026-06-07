# iOS Configuration

## Auth (Supabase OAuth)

Google and Apple sign-in use **Supabase browser OAuth** (not the native `google_sign_in` SDK).

### Deep link (required)

- **Bundle ID:** `com.viralai.cinemorph`
- **OAuth redirect URL:** `com.viralai.cinemorph://login-callback`
- **Email confirm:** `com.viralai.cinemorph://email-auth`
- **Password reset:** `com.viralai.cinemorph://reset-password`
- Registered in `ios/Runner/Info.plist` → `CFBundleURLSchemes`

### Supabase Dashboard

Add all redirect URLs under **Authentication → URL Configuration → Redirect URLs**.

See [supabase_oauth_setup.md](./supabase_oauth_setup.md) and [supabase_email_auth_setup.md](./supabase_email_auth_setup.md).

### Capabilities

- Enable **Sign in with Apple** capability in the Runner target (for Apple OAuth via Supabase).

## RevenueCat

- Ensure In-App Purchase capability enabled.
- Verify product IDs match RevenueCat packages.

## Push Notifications

- Enable Push Notifications + Background Modes (`remote-notification`).
- Upload APNs key/cert for Firebase project.

## Privacy / Review

- Add privacy nutrition labels.
- Include account deletion entry point in profile/settings.
- Ensure Terms and Privacy links are accessible in app.
