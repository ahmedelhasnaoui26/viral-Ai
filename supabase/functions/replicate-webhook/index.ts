import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

import { ExtendVideoService } from '../_shared/extend_video_service.ts';
import type { ReplicatePrediction } from '../_shared/replicate_service.ts';
import { VideoStorageService } from '../_shared/video_storage_service.ts';

declare const EdgeRuntime: {
  waitUntil: (promise: Promise<unknown>) => void;
};

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const videoStorage = new VideoStorageService(supabase);
const extendVideo = new ExtendVideoService(supabase);

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });
  }

  const url = new URL(req.url);
  const secret = url.searchParams.get('secret') ?? '';
  const expected = Deno.env.get('REPLICATE_WEBHOOK_SECRET')?.trim() ?? '';
  if (!expected || secret !== expected) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  }

  let prediction: ReplicatePrediction;
  try {
    prediction = (await req.json()) as ReplicatePrediction;
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400 });
  }

  if (!prediction?.id) {
    return new Response(JSON.stringify({ error: 'Missing prediction id' }), { status: 400 });
  }

  console.log('[replicate-webhook]', prediction.id, prediction.status);

  const { data: clip } = await supabase
    .from('generation_clips')
    .select('job_id')
    .eq('provider_job_id', prediction.id)
    .maybeSingle();

  const work = clip
    ? extendVideo.handleClipWebhook(prediction)
    : videoStorage.handleWebhookPrediction(prediction);

  EdgeRuntime.waitUntil(
    work.catch((error) => {
      console.error('[replicate-webhook] processing failed', prediction.id, error);
    }),
  );

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'content-type': 'application/json' },
  });
});
