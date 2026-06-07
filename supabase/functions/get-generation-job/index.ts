import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

import { ExtendVideoService } from '../_shared/extend_video_service.ts';
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

/** Heavy archival must not run inside the poll request (OOM / CPU limits). */
function scheduleBackground(task: Promise<unknown>): void {
  try {
    EdgeRuntime.waitUntil(task);
  } catch {
    task.catch((error) => console.error('[get-generation-job] background task failed', error));
  }
}

function jobResponse(job: Record<string, unknown>) {
  const outputKey = (job.output_object_key as string | null) ?? '';
  const r2VideoUrl = (job.r2_video_url as string | null) ?? null;

  return {
    jobId: job.id,
    status: job.status,
    objectKey: outputKey,
    outputObjectKey: outputKey,
    outputUrl: outputKey || null,
    r2VideoUrl,
    errorMessage: job.error_message ?? null,
    isExtended: job.is_extended ?? false,
    clipCount: job.clip_count ?? 1,
    completedClips: job.completed_clips ?? 0,
    progressPercent: job.progress_percent ?? 0,
    extendPhase: job.extend_phase ?? null,
    targetDurationSeconds: job.target_duration_seconds ?? job.duration_seconds ?? 5,
  };
}

serve(async (req: Request) => {
  const { jobId } = await req.json();
  if (!jobId) {
    return new Response(JSON.stringify({ error: 'Missing jobId' }), { status: 400 });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    });
  }
  const { data: userResult, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userResult?.user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    });
  }

  const { data: job, error } = await supabase
    .from('generation_jobs')
    .select('*')
    .eq('id', jobId)
    .single();
  if (error || !job) {
    return new Response(JSON.stringify({ error: error?.message ?? 'Not found' }), { status: 404 });
  }

  if (job.user_id !== userResult.user.id) {
    return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });
  }

  // Return DB state immediately; continue pipeline in the background if needed.
  if (job.is_extended && job.status === 'processing' && job.provider_job_id) {
    scheduleBackground(
      extendVideo.syncExtendedJob(job).catch((error) => {
        console.error('[get-generation-job] extended sync failed', jobId, error);
      }),
    );
  } else if (
    job.provider === 'replicate' &&
    job.provider_job_id &&
    (job.status === 'processing' || job.status === 'archiving')
  ) {
    scheduleBackground(
      videoStorage.syncProcessingJob({
        id: job.id as string,
        status: job.status as string,
        provider_job_id: job.provider_job_id as string,
        output_object_key: job.output_object_key as string | null,
      }).catch((error) => {
        console.error('[get-generation-job] single-clip sync failed', jobId, error);
      }),
    );
  }

  const { data: refreshed } = await supabase.from('generation_jobs').select('*').eq('id', jobId)
    .single();

  return new Response(JSON.stringify(jobResponse(refreshed ?? job)), {
    headers: { 'content-type': 'application/json' },
  });
});
