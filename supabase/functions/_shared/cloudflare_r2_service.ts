import { fetchWithTimeout, normalizeHttpsUrl } from './fetch.ts';

type SignerUploadResponse = {
  objectKey: string;
  signedUrl: string;
  error?: string;
};

function signerConfig(): { url: string; token: string } {
  const url = normalizeHttpsUrl(Deno.env.get('R2_SIGNER_URL') ?? '');
  const token = Deno.env.get('R2_SIGNER_TOKEN')?.trim() ?? '';
  if (!url || !token) {
    throw new Error('R2 signer is not configured (R2_SIGNER_URL / R2_SIGNER_TOKEN)');
  }
  return { url, token };
}

/** Permanent public URL for an object stored in the R2 public bucket. */
export function buildPublicR2Url(objectKey: string): string {
  const publicAssetBase = Deno.env.get('PUBLIC_ASSET_BASE_URL');
  if (!publicAssetBase) {
    throw new Error('PUBLIC_ASSET_BASE_URL is not configured');
  }
  const base = normalizeHttpsUrl(publicAssetBase);
  return `${base}/${objectKey}`;
}

/** Request a presigned PUT URL for a deterministic output key. */
export async function requestPresignedUpload(
  objectKey: string,
  contentType = 'video/mp4',
): Promise<SignerUploadResponse> {
  const { url, token } = signerConfig();

  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      operation: 'upload',
      fileName: 'output.mp4',
      objectKey,
      contentType,
    }),
    timeoutMs: 25_000,
  });

  const bodyText = await response.text();
  let parsed: SignerUploadResponse;
  try {
    parsed = bodyText ? JSON.parse(bodyText) : ({} as SignerUploadResponse);
  } catch {
    throw new Error('R2 signer returned invalid JSON');
  }

  if (!response.ok || parsed.error) {
    throw new Error(parsed.error ?? `R2 presign upload failed (${response.status})`);
  }

  if (!parsed.signedUrl || !parsed.objectKey) {
    throw new Error('R2 signer response missing signedUrl or objectKey');
  }

  return parsed;
}

/** Step 4 — Stream the downloaded video bytes into R2 (no full in-memory buffer). */
export async function uploadVideoToR2(params: {
  objectKey: string;
  body: ReadableStream<Uint8Array> | Uint8Array | ArrayBuffer;
  contentType?: string;
}): Promise<{ objectKey: string; r2VideoUrl: string }> {
  console.log('[CloudflareR2Service] Uploading video to R2…', params.objectKey);

  const contentType = params.contentType ?? 'video/mp4';
  const { signedUrl, objectKey } = await requestPresignedUpload(params.objectKey, contentType);
  const uploadBody = params.body instanceof ReadableStream
    ? params.body
    : new Uint8Array(params.body);

  const uploadResponse = await fetchWithTimeout(signedUrl, {
    method: 'PUT',
    headers: { 'content-type': contentType },
    body: uploadBody,
    timeoutMs: 180_000,
  });

  if (!uploadResponse.ok) {
    const preview = (await uploadResponse.text()).slice(0, 200);
    console.error('[CloudflareR2Service] Upload failed', uploadResponse.status, preview);
    throw new Error(`R2 upload failed (${uploadResponse.status})`);
  }

  const r2VideoUrl = buildPublicR2Url(objectKey);
  console.log('[CloudflareR2Service] Upload complete', r2VideoUrl);
  return { objectKey, r2VideoUrl };
}

/** Standard output object key for a generation job. */
export function outputObjectKeyForJob(jobId: string): string {
  return `outputs/${jobId}.mp4`;
}

/** Wait until a clip MP4 exists in R2; returns a presigned GET URL for ffmpeg merge. */
export async function waitUntilClipInR2(
  objectKey: string,
  options: { maxAttempts?: number; delayMs?: number } = {},
): Promise<string> {
  const maxAttempts = options.maxAttempts ?? 20;
  const delayMs = options.delayMs ?? 600;
  let lastStatus = 0;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const signedUrl = await requestPresignedDownload(objectKey);
    const probe = await fetchWithTimeout(signedUrl, {
      method: 'GET',
      headers: { range: 'bytes=0-1023' },
      timeoutMs: 20_000,
    });
    if (probe.ok || probe.status === 206) {
      const bytes = await probe.arrayBuffer();
      if (bytes.byteLength >= 1000) {
        console.log('[CloudflareR2Service] Clip ready in R2', objectKey);
        return signedUrl;
      }
    }
    lastStatus = probe.status;
    if (attempt < maxAttempts) {
      await new Promise((r) => setTimeout(r, delayMs * attempt));
    }
  }

  throw new Error(
    `Clip not found in R2 (${objectKey}). Last HTTP status: ${lastStatus}. ` +
      'Earlier clips may not have finished uploading.',
  );
}

/** URL for ffmpeg merge — presigned GET (outputs/ clips are often private on the public CDN). */
export async function resolveClipDownloadUrl(objectKey: string): Promise<string> {
  return await waitUntilClipInR2(objectKey);
}

/** Upload a JPEG/PNG frame to R2. */
export async function uploadImageToR2(params: {
  objectKey: string;
  body: Uint8Array | ArrayBuffer;
  contentType?: string;
}): Promise<{ objectKey: string; publicUrl: string }> {
  const contentType = params.contentType ?? 'image/jpeg';
  const { signedUrl, objectKey } = await requestPresignedUpload(params.objectKey, contentType);

  const uploadResponse = await fetchWithTimeout(signedUrl, {
    method: 'PUT',
    headers: { 'content-type': contentType },
    body: params.body,
    timeoutMs: 60_000,
  });

  if (!uploadResponse.ok) {
    const preview = (await uploadResponse.text()).slice(0, 200);
    throw new Error(`R2 frame upload failed (${uploadResponse.status}): ${preview}`);
  }

  const publicUrl = buildPublicR2Url(objectKey);
  const size = params.body instanceof ArrayBuffer ? params.body.byteLength : params.body.byteLength;
  console.log('[CloudflareR2Service] Frame upload complete', objectKey, size);
  return { objectKey, publicUrl };
}

/** Verify object exists (GET range probe). Returns URL Replicate can fetch. */
export async function resolveReplicateInputImageUrl(
  objectKey: string,
  options: { maxAttempts?: number; delayMs?: number } = {},
): Promise<string> {
  const maxAttempts = options.maxAttempts ?? 15;
  const delayMs = options.delayMs ?? 500;
  const publicUrl = buildPublicR2Url(objectKey);
  let lastStatus = 0;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const publicProbe = await fetchWithTimeout(publicUrl, {
        method: 'GET',
        headers: { range: 'bytes=0-511' },
        timeoutMs: 15_000,
      });
      if (publicProbe.ok || publicProbe.status === 206) {
        const bytes = await publicProbe.arrayBuffer();
        if (bytes.byteLength >= 500) {
          console.log('[CloudflareR2Service] Replicate input (public)', objectKey);
          return publicUrl;
        }
      }
      lastStatus = publicProbe.status;
    } catch {
      /* try presigned */
    }

    const signedUrl = await requestPresignedDownload(objectKey);
    const signedProbe = await fetchWithTimeout(signedUrl, {
      method: 'GET',
      headers: { range: 'bytes=0-511' },
      timeoutMs: 15_000,
    });
    if (signedProbe.ok || signedProbe.status === 206) {
      const bytes = await signedProbe.arrayBuffer();
      if (bytes.byteLength >= 500) {
        const publicRetry = await fetchWithTimeout(publicUrl, {
          method: 'GET',
          headers: { range: 'bytes=0-0' },
          timeoutMs: 10_000,
        });
        if (publicRetry.ok || publicRetry.status === 206) return publicUrl;
        console.warn('[CloudflareR2Service] Using presigned URL for Replicate input', objectKey);
        return signedUrl;
      }
    }
    lastStatus = signedProbe.status;

    if (attempt < maxAttempts) {
      await new Promise((r) => setTimeout(r, delayMs * attempt));
    }
  }

  throw new Error(
    `Input image not found in R2 (${objectKey}). Last HTTP status: ${lastStatus}. ` +
      'Check PUBLIC_ASSET_BASE_URL matches your public R2 domain.',
  );
}

/** Presigned GET URL for downloading an R2 object (ffmpeg processor input). */
export async function requestPresignedDownload(objectKey: string): Promise<string> {
  const { url, token } = signerConfig();

  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ operation: 'download', objectKey }),
    timeoutMs: 25_000,
  });

  const bodyText = await response.text();
  let parsed: SignerUploadResponse;
  try {
    parsed = bodyText ? JSON.parse(bodyText) : ({} as SignerUploadResponse);
  } catch {
    throw new Error('R2 signer returned invalid JSON');
  }

  if (!response.ok || parsed.error || !parsed.signedUrl) {
    throw new Error(parsed.error ?? `R2 presign download failed (${response.status})`);
  }

  return parsed.signedUrl;
}

/** True when the value is already an R2 key (not a temporary HTTPS URL). */
export function isPermanentR2ObjectKey(value: string | null | undefined): boolean {
  if (!value) return false;
  return value.startsWith('outputs/') || value.startsWith('uploads/');
}
