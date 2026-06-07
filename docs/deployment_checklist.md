# Deployment Checklist

- Apply `supabase/schema.sql`.
- Apply `supabase/migrations/002_social_platform.sql` (likes, saves, follows, notifications).
- Deploy Edge Functions:
  - `create-generation-job`
  - `get-generation-job`
  - `sign-r2-object`
  - `publish-generation`
  - `delete-account`
- Set Supabase function secrets (see [supabase_secrets_and_deploy.md](./supabase_secrets_and_deploy.md)) — **required** for `R2_SIGNER_URL` + `R2_SIGNER_TOKEN`.
- Redeploy functions after setting secrets.
- Deploy Cloudflare R2 signer Worker (`cloudflare/r2-signer-worker/`) — must return JSON, not `Hello World!`.
- Seed `feed_items` with starter videos.
- Validate sign-in flows on real iOS/Android devices.
- Validate generation start->poll->result path with live model.
- Validate purchase and restore in sandbox/test environment.
- Ship TestFlight/Internal Testing before store submission.
