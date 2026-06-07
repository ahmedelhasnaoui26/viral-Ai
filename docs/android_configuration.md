# Android Configuration

## Auth

- Configure SHA-1/SHA-256 in Google Cloud/Firebase for Google Sign-In.
- Add intent filters for Supabase callback if needed by auth provider setup.

## Billing

- Configure Play Billing products matching RevenueCat packages.
- Upload internal testing build and validate purchase/restore.

## Push Notifications

- Add `google-services.json`.
- Verify Firebase messaging permission/channel behavior.

## Release

- Configure release signing in `android/app/build.gradle.kts`.
- Enable minify/r8 and upload mapping files for crash symbolication.
