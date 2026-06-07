# R2 Signer Worker (CineMorph)

Supabase `sign-r2-object` calls this Worker to get presigned R2 URLs.

**Your Worker currently returns `Hello World!`** — replace it with this code.

## 1. R2 API token (Cloudflare Dashboard)

1. **R2 → Manage R2 API Tokens → Create API token**
2. Permissions: Object Read & Write on your bucket
3. Note: **Access Key ID**, **Secret Access Key**, **Account ID**, **Bucket name**

## 2. Install and configure

```bash
cd cloudflare/r2-signer-worker
npm install
```

Edit `wrangler.jsonc` — set `"name"` to your existing Worker name (`sweet-cloud-34c9`).

## 3. Set Worker secrets

`SIGNER_TOKEN` must be **identical** to Supabase secret `R2_SIGNER_TOKEN`.

If the app shows **Unauthorized**, the tokens do not match. Pick one value, set it in both places, then:

```bash
npx wrangler secret put SIGNER_TOKEN
supabase secrets set R2_SIGNER_TOKEN=THE_SAME_VALUE
supabase functions deploy sign-r2-object
```

```bash
npx wrangler secret put SIGNER_TOKEN
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY
npx wrangler secret put R2_ACCOUNT_ID
npx wrangler secret put R2_BUCKET_NAME
```

## 4. Deploy

```bash
npx wrangler deploy
```

## 5. Test

Opening the URL in a browser sends **GET** and only shows a health message.  
Use **POST** (curl or the app) to sign uploads.

```bash
curl -X POST "https://sweet-cloud-34c9.ahmedelhasnaouiapple2021.workers.dev" \
  -H "Authorization: Bearer YOUR_SIGNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"operation":"upload","fileName":"test.jpg","contentType":"image/jpeg"}'
```

Expected JSON (not `Hello World!`):

```json
{"objectKey":"uploads/...","signedUrl":"https://...r2.cloudflarestorage.com/..."}
```

## 6. R2 CORS (required for app upload)

In **R2 bucket → Settings → CORS**, allow PUT from your app:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

## 7. Public bucket URL

Supabase `PUBLIC_ASSET_BASE_URL` must match your public R2 domain (e.g. `https://pub-....r2.dev`) so Replicate can fetch uploaded images.
