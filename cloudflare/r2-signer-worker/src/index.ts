import { AwsClient } from 'aws4fetch';

export interface Env {
  /** Must match Supabase secret R2_SIGNER_TOKEN */
  SIGNER_TOKEN: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_ACCOUNT_ID: string;
  R2_BUCKET_NAME: string;
}

type SignRequest =
  | { operation: 'upload'; fileName: string; contentType?: string; objectKey?: string }
  | { operation: 'download'; objectKey: string };

const corsHeaders: Record<string, string> = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  });
}

function sanitizeFileName(fileName: string): string {
  const base = fileName.split('/').pop() ?? 'upload.jpg';
  return base.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 120) || 'upload.jpg';
}

function sanitizeObjectKey(objectKey: string): string | null {
  const trimmed = objectKey.trim();
  if (!trimmed || trimmed.includes('..')) return null;
  if (!/^(uploads|outputs)\/[a-zA-Z0-9._/-]+$/.test(trimmed)) return null;
  return trimmed;
}

async function presign(
  env: Env,
  method: 'GET' | 'PUT',
  objectKey: string,
): Promise<string> {
  const client = new AwsClient({
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    service: 's3',
    region: 'auto',
  });

  const expires = 3600;
  const r2Host = `${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const url = `https://${r2Host}/${env.R2_BUCKET_NAME}/${objectKey}?X-Amz-Expires=${expires}`;

  const signed = await client.sign(
    new Request(url, { method }),
    { aws: { signQuery: true } },
  );
  return signed.url.toString();
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method === 'GET') {
      return json({
        ok: true,
        service: 'cinemorph-r2-signer',
        hint: 'POST with Authorization: Bearer <token> and JSON body for upload/download.',
      });
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405);
    }

    const auth = request.headers.get('authorization') ?? '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!env.SIGNER_TOKEN || token !== env.SIGNER_TOKEN) {
      return json({ error: 'Unauthorized' }, 401);
    }

    for (const key of [
      'R2_ACCESS_KEY_ID',
      'R2_SECRET_ACCESS_KEY',
      'R2_ACCOUNT_ID',
      'R2_BUCKET_NAME',
    ] as const) {
      if (!env[key]?.trim()) {
        return json({ error: `Worker secret ${key} is not set` }, 500);
      }
    }

    let body: SignRequest;
    try {
      body = (await request.json()) as SignRequest;
    } catch {
      return json({ error: 'Invalid JSON body' }, 400);
    }

    try {
      if (body.operation === 'upload') {
        if (!body.fileName && !body.objectKey) {
          return json({ error: 'fileName or objectKey is required for upload' }, 400);
        }
        let objectKey: string;
        if (body.objectKey) {
          const safe = sanitizeObjectKey(body.objectKey);
          if (!safe) {
            return json({ error: 'Invalid objectKey (must start with uploads/ or outputs/)' }, 400);
          }
          objectKey = safe;
        } else {
          const safeName = sanitizeFileName(body.fileName);
          objectKey = `uploads/${crypto.randomUUID()}-${safeName}`;
        }
        const signedUrl = await presign(env, 'PUT', objectKey);
        return json({ objectKey, signedUrl });
      }

      if (body.operation === 'download') {
        if (!body.objectKey) {
          return json({ error: 'objectKey is required for download' }, 400);
        }
        const signedUrl = await presign(env, 'GET', body.objectKey);
        return json({ objectKey: body.objectKey, signedUrl });
      }

      return json({ error: 'Unknown operation' }, 400);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Presign failed';
      return json({ error: message }, 500);
    }
  },
};
