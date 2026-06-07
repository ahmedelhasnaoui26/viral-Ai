# Viral AI Image-to-Video App

Production-oriented Flutter MVP architecture for a consumer UGC AI video app.

## Stack

- Flutter + Riverpod + GoRouter
- Supabase (Auth, Postgres, Edge Functions)
- Cloudflare R2 (signed URL media flow)
- RevenueCat (subscriptions and entitlements)
- Fal AI + Replicate (orchestrated via Supabase Edge Functions)
- Mixpanel + PostHog (dual analytics sinks)

## Folder Structure

- `lib/app/`: app bootstrap, root widget, router
- `lib/core/`: config, theme, errors, analytics, network/retry, DI
- `lib/features/`:
  - `auth/`: auth service and session hooks
  - `onboarding/`: first-run funnel
  - `feed/`: TikTok-style vertical feed shell
  - `generation/`: domain contracts + data repository + generation controller
  - `paywall/`: monetization entry points
- `lib/shared/widgets/`: reusable branded widgets
- `supabase/functions/`: secure backend orchestration contracts

## Install

```bash
flutter pub get
```

## Run (local)

Use dart defines for runtime secrets:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=REVENUECAT_APPLE_API_KEY=YOUR_KEY \
  --dart-define=MIXPANEL_TOKEN=YOUR_TOKEN \
  --dart-define=POSTHOG_API_KEY=YOUR_TOKEN \
  --dart-define=POSTHOG_HOST=https://us.i.posthog.com
```

## Supabase Edge Functions

Create and deploy the function contracts:

- `create-generation-job`
- `get-generation-job`
- `sign-r2-object`
- `delete-account`

Apply database schema:

```bash
psql "$SUPABASE_DB_URL" -f supabase/schema.sql
```

These functions should:

1. Validate auth/session.
2. Route to Fal or Replicate based on cost/latency policy.
3. Persist job state in Supabase.
4. Return signed output URLs (R2) without exposing provider secrets to mobile.

## iOS Performance Standards

- Defer non-critical SDK initialization until after first frame.
- Keep feed rendering lightweight and isolate heavy image processing off UI thread.
- Use progressive media loading and caching for first-3-item feed smoothness.

## Analytics Taxonomy (MVP)

- `app_opened`
- `onboarding_started`
- `onboarding_completed`
- `sign_in_success`
- `generation_started`
- `generation_completed`
- `generation_failed`
- `paywall_viewed`
- `subscription_started`
- `share_tapped`
- `export_completed`
- `retention_day_1`
- `retention_day_7`

## Production Setup Docs

- `docs/environment_setup.md`
- `docs/revenuecat_setup.md`
- `docs/ios_configuration.md`
- `docs/android_configuration.md`
- `docs/deployment_checklist.md`
- `docs/app_store_release_checklist.md`
- `docs/ci_cd_recommendation.md`
