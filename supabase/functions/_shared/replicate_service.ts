import { fetchWithTimeout, normalizeHttpsUrl } from './fetch.ts';

export type ReplicatePrediction = {
  id: string;
  status: string;
  output?: string | string[] | null;
  error?: string | null;
};

const REPLICATE_API = 'https://api.replicate.com/v1/predictions';

function replicateToken(): string {
  const token = Deno.env.get('REPLICATE_API_TOKEN')?.trim();
  if (!token) {
    throw new Error('REPLICATE_API_TOKEN is not configured');
  }
  return token;
}

function replicateModelVersion(): string {
  const version = Deno.env.get('REPLICATE_MODEL_VERSION')?.trim();
  if (!version) {
    throw new Error('REPLICATE_MODEL_VERSION is not configured');
  }
  return version;
}

/** Step 1 — Create a Replicate prediction for image-to-video inference. */
export async function createPrediction(params: {
  inputImageUrl: string;
  prompt: string;
  style: string;
  webhookUrl?: string;
}): Promise<ReplicatePrediction> {
  console.log('[ReplicateService] Creating prediction…');

  const body: Record<string, unknown> = {
    version: replicateModelVersion(),
    input: {
      image: params.inputImageUrl,
      prompt: params.prompt,
      style: params.style,
    },
  };

  if (params.webhookUrl) {
    body.webhook = params.webhookUrl;
    body.webhook_events_filter = ['completed'];
  }

  const response = await fetchWithTimeout(REPLICATE_API, {
    method: 'POST',
    headers: {
      authorization: `Token ${replicateToken()}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
    timeoutMs: 45_000,
  });

  const text = await response.text();
  if (!response.ok) {
    console.error('[ReplicateService] createPrediction failed', response.status, text);
    throw new Error(text || `Replicate create failed (${response.status})`);
  }

  const prediction = JSON.parse(text) as ReplicatePrediction;
  console.log('[ReplicateService] Prediction created', prediction.id, prediction.status);
  return prediction;
}

/** Step 2 — Poll Replicate until the prediction completes, fails, or times out. */
export async function pollPredictionUntilCompleted(
  predictionId: string,
  options: { timeoutMs?: number; intervalMs?: number } = {},
): Promise<ReplicatePrediction> {
  const timeoutMs = options.timeoutMs ?? 600_000;
  const intervalMs = options.intervalMs ?? 3_000;
  const deadline = Date.now() + timeoutMs;

  console.log('[ReplicateService] Polling prediction', predictionId);

  while (Date.now() < deadline) {
    const prediction = await getPrediction(predictionId);

    if (prediction.status === 'succeeded') {
      console.log('[ReplicateService] Prediction succeeded', predictionId);
      return prediction;
    }

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      console.error('[ReplicateService] Prediction failed', predictionId, prediction.error);
      throw new Error(prediction.error ?? `Prediction ${prediction.status}`);
    }

    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }

  throw new Error(`Replicate prediction timed out after ${timeoutMs / 1000}s`);
}

/** Fetch a single prediction snapshot (used by polling and webhooks). */
export async function getPrediction(predictionId: string): Promise<ReplicatePrediction> {
  const response = await fetchWithTimeout(`${REPLICATE_API}/${predictionId}`, {
    headers: { authorization: `Token ${replicateToken()}` },
    timeoutMs: 20_000,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `Replicate poll failed (${response.status})`);
  }

  return (await response.json()) as ReplicatePrediction;
}

/** Extract the first video URL from a completed prediction output. */
export function extractOutputVideoUrl(prediction: ReplicatePrediction): string {
  const raw = prediction.output;
  const url = Array.isArray(raw) ? raw[0] : raw;
  if (typeof url !== 'string' || !url.startsWith('http')) {
    throw new Error('Replicate prediction succeeded but output video URL is missing');
  }
  return url;
}

/** Step 3 — Download the temporary Replicate video (streaming response body). */
export async function downloadVideoFromReplicate(replicateUrl: string): Promise<Response> {
  console.log('[ReplicateService] Downloading video from Replicate CDN…');

  const response = await fetchWithTimeout(replicateUrl, {
    method: 'GET',
    timeoutMs: 120_000,
  });

  if (!response.ok || !response.body) {
    const preview = (await response.text()).slice(0, 200);
    console.error('[ReplicateService] Download failed', response.status, preview);
    throw new Error(`Failed to download video from Replicate (${response.status})`);
  }

  const contentType = response.headers.get('content-type') ?? 'video/mp4';
  if (!contentType.includes('video') && !contentType.includes('octet-stream')) {
    console.warn('[ReplicateService] Unexpected content-type:', contentType);
  }

  return response;
}

/** Build the public input image URL Replicate reads during inference. */
export function buildPublicInputImageUrl(objectKey: string): string {
  const publicAssetBase = Deno.env.get('PUBLIC_ASSET_BASE_URL');
  if (!publicAssetBase) {
    throw new Error('PUBLIC_ASSET_BASE_URL is not configured');
  }
  const base = normalizeHttpsUrl(publicAssetBase);
  return `${base}/${objectKey}`;
}

/** Optional webhook URL passed when creating predictions. */
export function buildReplicateWebhookUrl(): string | undefined {
  const secret = Deno.env.get('REPLICATE_WEBHOOK_SECRET')?.trim();
  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim();
  if (!secret || !supabaseUrl) return undefined;
  const base = normalizeHttpsUrl(supabaseUrl);
  return `${base}/functions/v1/replicate-webhook?secret=${encodeURIComponent(secret)}`;
}
