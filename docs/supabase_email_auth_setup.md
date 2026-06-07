# Supabase Email + Password Auth

## Dashboard (Authentication)

1. **Providers → Email**: enable Email provider.
2. **Confirm email**: enable **Confirm email** so new users must verify before sign-in.
3. **URL Configuration** — add these **Redirect URLs** (in addition to OAuth):

| URL | Purpose |
|-----|---------|
| `com.viralai.cinemorph://login-callback` | Google / Apple OAuth |
| `com.viralai.cinemorph://email-auth` | Email confirmation |
| `com.viralai.cinemorph://reset-password` | Password recovery |

4. **Site URL**: `com.viralai.cinemorph://login-callback` (or your production web URL).

## Mobile deep links

- iOS: `CFBundleURLSchemes` = `com.viralai.cinemorph` (already in `Info.plist`)
- Android: intent-filter hosts `login-callback`, `reset-password`, `email-auth` in `AndroidManifest.xml`

## App routes

| Route | Screen |
|-------|--------|
| `/auth` | Sign In (email + OAuth + guest) |
| `/auth/sign-up` | Create Account |
| `/auth/forgot-password` | Forgot Password |
| `/reset-password` | Reset Password (opened from recovery email) |

## Guest mode

Guests can browse; sign-in is required for generate, publish, save, like, comment, and follow (enforced via `requireAuthentication`).
