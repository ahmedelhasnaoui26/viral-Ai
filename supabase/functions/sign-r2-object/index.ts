import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { fetchWithTimeout } from '../_shared/fetch.ts';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

/** Supabase secrets are sometimes set without a scheme; fetch() requires https:// */
function normalizeSignerUrl(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return trimmed;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  return `https://${trimmed}`;
}

serve(async (req: Request) => {
  try {
    const { operation, objectKey, fileName, contentType } = await req.json();
    if (!operation || (operation === 'download' && !objectKey)) {
      return json({ error: 'Invalid sign request' }, 400);
    }

    const signerUrl = normalizeSignerUrl(Deno.env.get('R2_SIGNER_URL') ?? '');
    const signerToken = Deno.env.get('R2_SIGNER_TOKEN')?.trim();
    if (!signerUrl || !signerToken) {
      const missing = [
        !signerUrl ? 'R2_SIGNER_URL' : null,
        !signerToken ? 'R2_SIGNER_TOKEN' : null,
      ].filter(Boolean);
      return json(
        {
          error: 'Signer not configured',
          missingSecrets: missing,
          hint:
            'Set secrets in Supabase Dashboard → Edge Functions → Secrets, then redeploy sign-r2-object',
        },
        500,
      );
    }

    const payload =
      operation === 'upload'
        ? { operation, fileName, contentType }
        : { operation, objectKey };

    const signerResponse = await fetchWithTimeout(signerUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${signerToken}`,
      },
      body: JSON.stringify(payload),
      timeoutMs: 25_000,
    });

    const bodyText = await signerResponse.text();
    let signed: Record<string, unknown>;
    try {
      signed = bodyText ? JSON.parse(bodyText) : {};
    } catch {
      return json(
        {
          error: 'R2 signer returned invalid JSON (is the Cloudflare Worker deployed?)',
          signerStatus: signerResponse.status,
          preview: bodyText.slice(0, 120),
        },
        502,
      );
    }

    if (!signerResponse.ok) {
      if (signerResponse.status === 401) {
        return json(
          {
            error: 'R2 signer token rejected',
            hint:
              'Cloudflare Worker secret SIGNER_TOKEN must exactly match Supabase secret R2_SIGNER_TOKEN (redeploy both after changing).',
          },
          401,
        );
      }
      return json(
        {
          error:
            (typeof signed.error === 'string' && signed.error) ||
            `Signer request failed (${signerResponse.status})`,
        },
        signerResponse.status >= 400 && signerResponse.status < 600
          ? signerResponse.status
          : 502,
      );
    }

    if (
      typeof signed.signedUrl !== 'string' ||
      typeof signed.objectKey !== 'string'
    ) {
      return json(
        {
          error: 'Signer response missing signedUrl or objectKey',
          received: Object.keys(signed),
        },
        502,
      );
    }

    return json(signed);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error';
    return json({ error: message }, 500);
  }
});
