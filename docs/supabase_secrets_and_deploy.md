# Supabase Secrets & Edge Function Deploy

If the app shows **"Signer not configured"**, the `sign-r2-object` function is deployed but **`R2_SIGNER_URL` and/or `R2_SIGNER_TOKEN` are missing** from Edge Function secrets.

## Option A — Supabase Dashboard (easiest)

1. Open [Supabase Dashboard](https://supabase.com/dashboard/project/ujlvhvkshbhyttrhxwvt/settings/functions)
2. Go to **Project Settings → Edge Functions → Secrets** (or **Edge Functions → Manage secrets**)
3. Add these secrets **exactly** (names are case-sensitive):

| Name | Example value |
|------|----------------|
| `R2_SIGNER_URL` | `https://sweet-cloud-34c9.ahmedelhasnaouiapple2021.workers.dev` |
| `R2_SIGNER_TOKEN` | *(your Cloudflare Worker bearer token)* |
| `REPLICATE_API_TOKEN` | `r8_...` |
| `REPLICATE_MODEL_VERSION` | Full **version hash** from Replicate API tab (64 chars, e.g. `abc123...`) — not the model name |
| `PUBLIC_ASSET_BASE_URL` | `https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev` |
| `REPLICATE_WEBHOOK_SECRET` | Random string (same value used in webhook URL query param) |
| `VIDEO_PROCESSOR_URL` | Railway public URL (15s / 30s / 60s only) — see above |
| `VIDEO_PROCESSOR_TOKEN` | Same bearer token as Railway `VIDEO_PROCESSOR_TOKEN` |

4. **Redeploy** functions (secrets apply to new deployments):

```bash
cd "/Users/ahmedelhasnaoui/Desktop/Flutter Project/viral_imagetovideo_app"
supabase login
supabase link --project-ref ujlvhvkshbhyttrhxwvt
supabase functions deploy sign-r2-object
supabase functions deploy create-generation-job
supabase functions deploy get-generation-job
supabase functions deploy replicate-webhook --no-verify-jwt
supabase functions deploy publish-generation
```

Also redeploy the Cloudflare R2 signer Worker after pulling (supports `objectKey` on upload for `outputs/{jobId}.mp4`).

Run migration `004_r2_permanent_video_storage.sql` in the SQL editor.

### Permanent video storage flow

Replicate output is **never** stored long-term. On completion the server:

1. Downloads the temporary Replicate CDN URL
2. Streams it into R2 at `outputs/{jobId}.mp4`
3. Saves `r2_video_url` + `output_object_key` on `generation_jobs`

### Extend Video (15s / 30s / 60s)

Extended durations generate **5-second Replicate clips**, chain the last frame into the next clip, then **ffmpeg merge** into one permanent MP4 on R2.

Deploy the video processor on **Railway** (recommended) — see [services/video-processor/README.md](../services/video-processor/README.md).

Run migration `005_extend_video.sql` in the SQL editor.

Polling (`get-generation-job`) and webhooks (`replicate-webhook`) both trigger archival.

**Required for 15s / 30s / 60s:** `VIDEO_PROCESSOR_URL` must point to the **ffmpeg Docker service** (`services/video-processor`), **not** the R2 signer Worker. After code changes, redeploy:

```bash
supabase functions deploy create-generation-job
supabase functions deploy get-generation-job
supabase functions deploy replicate-webhook --no-verify-jwt
```

### Extended video (15s+) — deploy video processor on Railway

Extended videos need the ffmpeg service (`services/video-processor`). Supabase cannot reach `localhost` — use a **permanent public URL** on Railway.

#### Step 1 — Push code, then Railway project

Railway builds from **GitHub**, not your laptop. Push the processor first:

```bash
git add services/video-processor/
git commit -m "Add video processor service"
git push origin main
```

Then:

1. [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**
2. Select this repo
3. **Service → Settings → Root Directory** → `services/video-processor` (exact path)
4. Railway builds from the `Dockerfile`

**Build error `lstat .../services: no such file or directory`?** The GitHub repo is missing `services/video-processor` — push the code above and click **Redeploy**.

**Alternative:** `cd services/video-processor && railway up` (CLI deploy from local files).

#### Step 2 — Variables

| Name | Value |
|------|--------|
| `VIDEO_PROCESSOR_TOKEN` | Random secret, e.g. `openssl rand -hex 32` |

Do **not** set `PORT` — Railway provides it.

#### Step 3 — Public domain

**Settings → Networking → Generate Domain** → copy URL  
Example: `https://cinemorph-video-processor-production.up.railway.app`

#### Step 4 — Verify

```bash
curl https://YOUR-RAILWAY-URL/health
```

Must return: `{"ok":true,"service":"cinemorph-video-processor"}`

#### Step 5 — Supabase secrets

Dashboard → **Edge Functions → Secrets**, or CLI:

```bash
supabase secrets set VIDEO_PROCESSOR_URL=https://YOUR-RAILWAY-URL
supabase secrets set VIDEO_PROCESSOR_TOKEN=same-token-as-railway
```

`VIDEO_PROCESSOR_TOKEN` must match **exactly** on Railway and Supabase.

Then try **15s** in the app.

#### Local dev (optional)

Use `./scripts/start-video-processor.sh` + ngrok only for local testing — not for production.

### `Frame image not found in R2` (older builds)

Fixed by passing frames to Replicate as `data:image/jpeg;base64,...` instead of requiring R2. You still need the video processor running for ffmpeg extract + final merge.

### `Download failed (404)` on extended videos

| Cause | Fix |
|-------|-----|
| Edge functions not redeployed | Run deploy commands above |
| `VIDEO_PROCESSOR_URL` missing or points to R2 signer | Set URL to your ffmpeg host; test `curl https://YOUR-HOST/health` |
| Video processor not running | `cd services/video-processor && docker build -t cinemorph-video-processor . && docker run -p 8080:8080 -e VIDEO_PROCESSOR_TOKEN=... cinemorph-video-processor` |
| Clips not on public R2 CDN | Ensure `PUBLIC_ASSET_BASE_URL` matches your public bucket; clips upload to `outputs/{jobId}/clips/` |

## Option B — CLI

```bash
supabase login
supabase link --project-ref ujlvhvkshbhyttrhxwvt

supabase secrets set \
  R2_SIGNER_URL=https://YOUR-WORKER.workers.dev \
  R2_SIGNER_TOKEN=YOUR_TOKEN \
  REPLICATE_API_TOKEN=r8_YOUR_TOKEN \
  REPLICATE_MODEL_VERSION=YOUR_MODEL_VERSION \
  PUBLIC_ASSET_BASE_URL=https://YOUR-R2-PUBLIC-URL.r2.dev

supabase functions deploy sign-r2-object
supabase functions deploy create-generation-job
supabase functions deploy get-generation-job
```

Verify secrets (names only, not values):

```bash
supabase secrets list
```

You should see `R2_SIGNER_URL` and `R2_SIGNER_TOKEN` in the list.

## R2_SIGNER_URL format

Must include **`https://`**:

- Wrong: `sweet-cloud-34c9.ahmedelhasnaouiapple2021.workers.dev`
- Right: `https://sweet-cloud-34c9.ahmedelhasnaouiapple2021.workers.dev`

## Database

Run `supabase/schema.sql` once in **SQL Editor** if `generation_jobs` does not exist.

## Deploy the R2 Signer Worker (required)

Your Worker URL must return **JSON**, not `Hello World!`.

Use the project in **`cloudflare/r2-signer-worker/`** — see its README for R2 API tokens and `wrangler deploy`.

`SIGNER_TOKEN` on the Worker must equal Supabase `R2_SIGNER_TOKEN`.

## Test Worker

```bash
curl -X POST "https://YOUR-WORKER.workers.dev" \
  -H "Authorization: Bearer YOUR_R2_SIGNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"operation":"upload","fileName":"test.jpg","contentType":"image/jpeg"}'
```

Expect JSON with `signedUrl` and `objectKey` — **not** `Hello World!`, 401, or 404.

## Fix Replicate `Invalid version` (422)

1. Go to [replicate.com/explore](https://replicate.com/explore) and pick an **image-to-video** model you can run (e.g. search “image to video”).
2. Open the model → **API** tab → copy the **`version`** id (long hash, ~64 characters).
3. Update Supabase:

```bash
supabase secrets set REPLICATE_MODEL_VERSION=YOUR_FULL_VERSION_HASH
supabase functions deploy create-generation-job
```

4. Ensure `REPLICATE_API_TOKEN` is from [replicate.com/account/api-tokens](https://replicate.com/account/api-tokens) and has access to that model.

The value `rwn48vjygdrma0ctqcgbrd06t4` is **too short** — that is not a valid Replicate version id.

## Testing: disable generation limits

While testing, limits can be bypassed (no daily free cap, no credit deduction):

1. In `supabase/functions/_shared/generation_limits.ts`, keep `DISABLE_GENERATION_LIMITS_DEV = true`.
2. Redeploy: `supabase functions deploy create-generation-job`

To re-enable limits later, set `DISABLE_GENERATION_LIMITS_DEV = false` and redeploy (or use secret `DISABLE_GENERATION_LIMITS=true` without changing code).

## Error progression

| Error | Meaning |
|-------|---------|
| `404 NOT_FOUND` | Functions not deployed |
| `Signer not configured` | Functions deployed, secrets missing |
| `Unauthorized` / `401` | **Token mismatch:** Cloudflare `SIGNER_TOKEN` must equal Supabase `R2_SIGNER_TOKEN` exactly (no extra spaces). Or sign out/in if session expired. |
| `Invalid version` / 422 | Wrong `REPLICATE_MODEL_VERSION` — use full hash from Replicate API tab |
