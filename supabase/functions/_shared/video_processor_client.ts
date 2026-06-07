import { requestPresignedDownload } from './cloudflare_r2_service.ts';
import { fetchWithTimeout, normalizeHttpsUrl } from './fetch.ts';

const MAX_ATTEMPTS = 3;

function processorConfig(): { url: string; token: string } {
  const url = normalizeHttpsUrl(Deno.env.get('VIDEO_PROCESSOR_URL') ?? '');
  const token = Deno.env.get('VIDEO_PROCESSOR_TOKEN')?.trim() ?? '';
  if (!url || !token) {
    throw new Error(
      'VIDEO_PROCESSOR_URL / VIDEO_PROCESSOR_TOKEN not configured (deploy services/video-processor)',
    );
  }
  return { url: url.replace(/\/$/, ''), token };
}

/** Headers for server-to-server calls (ngrok free tier returns HTML without this). */
function processorHeaders(token: string, extra: Record<string, string> = {}): Record<string, string> {
  return {
    authorization: `Bearer ${token}`,
    'ngrok-skip-browser-warning': 'true',
    ...extra,
  };
}

function parseProcessorError(url: string, text: string): Error {
  const trimmed = text.trim();
  if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
    const isNgrok = url.includes('ngrok');
    return new Error(
      isNgrok
        ? 'ngrok returned an HTML page instead of the video processor. ' +
          'Start Docker on port 8080, run `ngrok http 8080`, keep both terminals open, ' +
          'and verify: curl -H "ngrok-skip-browser-warning: true" https://YOUR-URL/health'
        : 'Video processor URL returned HTML (not running or wrong URL). ' +
          `Check ${url}/health returns JSON.`,
    );
  }
  return new Error(`Video processor returned invalid JSON: ${trimmed.slice(0, 120)}`);
}

async function postWithRetry<T>(path: string, body: unknown): Promise<T> {
  const { url, token } = processorConfig();
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      const response = await fetchWithTimeout(`${url}${path}`, {
        method: 'POST',
        headers: processorHeaders(token, { 'content-type': 'application/json' }),
        body: JSON.stringify(body),
        timeoutMs: 300_000,
      });
      const text = await response.text();
      let parsed: T & { error?: string };
      try {
        parsed = text ? JSON.parse(text) : ({} as T & { error?: string });
      } catch {
        throw parseProcessorError(url, text);
      }
      if (!response.ok || parsed.error) {
        if (response.status === 404) {
          throw new Error(
            `Video processor endpoint not found at ${url}${path}. ` +
              'Deploy services/video-processor and set VIDEO_PROCESSOR_URL to that host (not the R2 signer URL).',
          );
        }
        throw new Error(parsed.error ?? `Processor ${path} failed (${response.status})`);
      }
      return parsed;
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      console.warn(`[VideoProcessorClient] ${path} attempt ${attempt} failed`, lastError.message);
      if (attempt < MAX_ATTEMPTS) {
        await new Promise((r) => setTimeout(r, 1000 * attempt));
      }
    }
  }

  throw lastError ?? new Error(`Processor ${path} failed`);
}

type ExtractFrameResponse = { ok: boolean; frameBase64?: string; error?: string };

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  const chunk = 8192;
  for (let i = 0; i < bytes.length; i += chunk) {
    const slice = bytes.subarray(i, Math.min(i + chunk, bytes.length));
    binary += String.fromCharCode(...slice);
  }
  return btoa(binary);
}

function decodeBase64Frame(encoded: string): Uint8Array {
  const binary = atob(encoded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

/** Extract last frame from clip bytes (Edge already downloaded Replicate output). */
async function extractLastFrameFromVideoBytes(video: ArrayBuffer): Promise<Uint8Array> {
  console.log('[VideoProcessorClient] extract-last-frame-bytes', video.byteLength);
  const result = await postWithRetry<ExtractFrameResponse>('/extract-last-frame-bytes', {
    videoBase64: arrayBufferToBase64(video),
  });
  if (!result.frameBase64) {
    throw new Error('Video processor returned no frame bytes');
  }
  const bytes = decodeBase64Frame(result.frameBase64);
  if (bytes.byteLength < 100) {
    throw new Error(`Extracted frame is too small (${bytes.byteLength} bytes)`);
  }
  return bytes;
}

/** Download frame JPEG from R2 after legacy processor PUT upload. */
async function fetchFrameBytesFromR2(frameObjectKey: string): Promise<Uint8Array> {
  for (let attempt = 1; attempt <= 12; attempt++) {
    const signedUrl = await requestPresignedDownload(frameObjectKey);
    const response = await fetchWithTimeout(signedUrl, {
      method: 'GET',
      headers: { range: 'bytes=0-65535' },
      timeoutMs: 20_000,
    });
    if (response.ok || response.status === 206) {
      const bytes = new Uint8Array(await response.arrayBuffer());
      if (bytes.byteLength >= 100) return bytes;
    }
    if (attempt < 12) {
      await new Promise((r) => setTimeout(r, 500 * attempt));
    }
  }
  throw new Error(`Frame not found in R2 after processor upload (${frameObjectKey})`);
}

/**
 * Extract JPEG last frame for clip chaining.
 * Sends both URLs for Railway/legacy builds; prefers returnFrame bytes when supported.
 */
export async function extractFrameFromClip(
  replicateVideoUrl: string,
  frameUploadUrl: string,
  frameObjectKey: string,
): Promise<Uint8Array> {
  const errors: string[] = [];

  try {
    const result = await postWithRetry<ExtractFrameResponse>('/extract-last-frame', {
      sourceDownloadUrl: replicateVideoUrl,
      frameUploadUrl,
      returnFrame: true,
    });
    if (result.frameBase64) {
      const bytes = decodeBase64Frame(result.frameBase64);
      if (bytes.byteLength >= 100) return bytes;
    } else {
      console.log('[VideoProcessorClient] legacy processor uploaded frame to R2');
      return await fetchFrameBytesFromR2(frameObjectKey);
    }
  } catch (error) {
    errors.push(error instanceof Error ? error.message : String(error));
  }

  const { url } = processorConfig();
  throw new Error(
    `Frame extraction failed. Check ${url}/health and redeploy Railway from latest ` +
      `services/video-processor. Details: ${errors.join(' | ')}`,
  );
}

/** Replicate accepts HTTPS URLs or data:image/jpeg;base64,... */
export function frameBytesToDataUrl(bytes: Uint8Array): string {
  return `data:image/jpeg;base64,${arrayBufferToBase64(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength))}`;
}

/** Concatenate clip MP4s with ffmpeg and upload merged output to R2. */
export async function mergeClips(params: {
  clipDownloadUrls: string[];
  outputUploadUrl: string;
}): Promise<{ bytesWritten: number }> {
  console.log('[VideoProcessorClient] merge-clips', params.clipDownloadUrls.length);
  return await postWithRetry<{ bytesWritten: number }>('/merge-clips', {
    clipDownloadUrls: params.clipDownloadUrls,
    outputUploadUrl: params.outputUploadUrl,
  });
}
