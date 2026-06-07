# Environment Variables

## Flutter app (`--dart-define`)

Set these for local runs and CI:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_FUNCTIONS_URL`
- `SUPABASE_STORAGE_BUCKET`
- `REVENUECAT_APPLE_API_KEY`
- `REVENUECAT_GOOGLE_API_KEY`
- `MIXPANEL_TOKEN`
- `POSTHOG_API_KEY`
- `POSTHOG_HOST`
- `SENTRY_DSN`
- `APP_FLAVOR`

Defaults are in `lib/core/config/app_env.dart`.

## Supabase Edge Function secrets (server-side)

Set in **Dashboard → Edge Functions → Secrets** or via `supabase secrets set`.
**Redeploy functions after changing secrets.**

Required for video generation:

| Secret | Purpose |
|--------|---------|
| `R2_SIGNER_URL` | Cloudflare Worker URL (`https://...workers.dev`) |
| `R2_SIGNER_TOKEN` | Bearer token for the Worker |
| `REPLICATE_API_TOKEN` | Replicate API key |
| `REPLICATE_MODEL_VERSION` | Replicate model version id |
| `PUBLIC_ASSET_BASE_URL` | Public R2 bucket URL for input images |

Full deploy guide: [supabase_secrets_and_deploy.md](./supabase_secrets_and_deploy.md)

Also set in Supabase (auto-injected for functions):

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## Cloudflare Worker (R2 signer)

The Worker at `R2_SIGNER_URL` must accept:

```json
POST /
Authorization: Bearer <R2_SIGNER_TOKEN>
{ "operation": "upload", "fileName": "...", "contentType": "image/jpeg" }
```

Response: `{ "signedUrl": "...", "objectKey": "..." }`
