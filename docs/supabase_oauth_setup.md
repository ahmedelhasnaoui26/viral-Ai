# Supabase OAuth Setup Checklist

Use this checklist after pulling the mobile deep-link fixes.

## Redirect URL (app)

```
com.viralai.cinemorph://login-callback
```

## Supabase Dashboard

Project: `ujlvhvkshbhyttrhxwvt` (or your project ref)

### 1. Authentication → URL Configuration

| Setting | Value |
|--------|--------|
| **Site URL** | `com.viralai.cinemorph://login-callback` *(or your production web URL if you have one — do **not** leave `http://localhost:3000`)* |
| **Redirect URLs** (add all) | `com.viralai.cinemorph://login-callback` |
| | `com.viralai.cinemorph://**` *(optional wildcard for Supabase)* |

Remove or deprioritize `http://localhost:*` unless you actively use web dev auth.

### 2. Authentication → Providers → Google

- [ ] Google provider **enabled**
- [ ] Client ID + Client Secret from Google Cloud Console (Web application type)
- [ ] Authorized redirect URI in Google Cloud includes:
  ```
  https://ujlvhvkshbhyttrhxwvt.supabase.co/auth/v1/callback
  ```
  *(Replace with your project ref.)*

### 3. Authentication → Providers → Apple

- [ ] Apple provider **enabled** (if using Sign in with Apple)
- [ ] Services ID, Team ID, Key ID, and private key configured per [Supabase Apple docs](https://supabase.com/docs/guides/auth/social-login/auth-apple)

## Google Cloud Console

1. **APIs & Services → Credentials**
2. Create or edit **OAuth 2.0 Client ID** → type **Web application**
3. **Authorized redirect URIs:**
   ```
   https://<PROJECT_REF>.supabase.co/auth/v1/callback
   ```
4. Copy **Client ID** and **Client secret** into Supabase Google provider settings.

> Do **not** use an iOS OAuth client redirect to `localhost`. Supabase handles Google OAuth server-side; the mobile app only receives the final deep link.

## iOS (Xcode)

- [ ] Bundle ID: `com.viralai.cinemorph`
- [ ] `Info.plist` → URL Types → scheme `com.viralai.cinemorph`
- [ ] Sign in with Apple capability (optional but recommended for Apple OAuth)

## Android

- [ ] `AndroidManifest.xml` intent-filter for `com.viralai.cinemorph` / host `login-callback`

## Verify

1. Clean build: `flutter clean && cd ios && pod install && cd ..`
2. Run on device or simulator
3. Tap **Continue with Google**
4. After account selection, Safari should briefly show Supabase then redirect to the app (not `localhost`)
5. App should land on `/home` with an active session

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Safari opens `localhost` | Site URL or Redirect URLs in Supabase still point to localhost; add `com.viralai.cinemorph://login-callback` |
| App does not reopen after login | URL scheme missing in `Info.plist` or redirect URL mismatch |
| `redirect_uri_mismatch` in Google | Add Supabase callback URL to Google Cloud authorized redirect URIs |
