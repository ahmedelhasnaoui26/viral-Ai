import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';

export type VideoMetadataRecord = {
  id: string;
  user_id: string;
  original_image_url: string;
  replicate_prediction_id: string | null;
  prompt: string;
  style: string;
  duration: number;
  r2_video_url: string;
  output_object_key: string;
  replicate_output_url: string | null;
  created_at: string;
};

export type GenerationJobRow = {
  id: string;
  user_id: string;
  input_object_key: string;
  prompt: string;
  style: string;
  duration_seconds: number;
  status: string;
  provider: string;
  provider_job_id: string | null;
  output_object_key: string | null;
  r2_video_url: string | null;
  replicate_output_url: string | null;
  error_message: string | null;
  created_at: string;
  completed_at: string | null;
};

/** Step 5 — Persist permanent R2 metadata on the generation_jobs row. */
export async function saveVideoMetadataToSupabase(
  supabase: SupabaseClient,
  params: {
    jobId: string;
    outputObjectKey: string;
    r2VideoUrl: string;
    replicateOutputUrl: string;
  },
): Promise<VideoMetadataRecord> {
  console.log('[SupabaseVideoRepository] Saving video metadata…', params.jobId);

  const { data: row, error } = await supabase
    .from('generation_jobs')
    .update({
      status: 'completed',
      output_object_key: params.outputObjectKey,
      r2_video_url: params.r2VideoUrl,
      replicate_output_url: params.replicateOutputUrl,
      completed_at: new Date().toISOString(),
      error_message: null,
    })
    .eq('id', params.jobId)
    .select(
      'id, user_id, input_object_key, prompt, style, duration_seconds, provider_job_id, r2_video_url, output_object_key, replicate_output_url, created_at',
    )
    .single();

  if (error || !row) {
    console.error('[SupabaseVideoRepository] Save failed', error?.message);
    throw new Error(error?.message ?? 'Failed to save video metadata');
  }

  const publicBase = Deno.env.get('PUBLIC_ASSET_BASE_URL') ?? '';
  const originalImageUrl = publicBase
    ? `${publicBase.replace(/\/$/, '')}/${row.input_object_key as string}`
    : row.input_object_key as string;

  return {
    id: row.id as string,
    user_id: row.user_id as string,
    original_image_url: originalImageUrl,
    replicate_prediction_id: row.provider_job_id as string | null,
    prompt: row.prompt as string,
    style: row.style as string,
    duration: row.duration_seconds as number,
    r2_video_url: row.r2_video_url as string,
    output_object_key: row.output_object_key as string,
    replicate_output_url: row.replicate_output_url as string | null,
    created_at: row.created_at as string,
  };
}

export async function markJobArchiving(supabase: SupabaseClient, jobId: string): Promise<void> {
  await supabase.from('generation_jobs').update({ status: 'archiving' }).eq('id', jobId);
}

export async function markJobFailed(
  supabase: SupabaseClient,
  jobId: string,
  message: string,
): Promise<void> {
  await supabase
    .from('generation_jobs')
    .update({ status: 'failed', error_message: message })
    .eq('id', jobId);
}

export async function findJobByPredictionId(
  supabase: SupabaseClient,
  predictionId: string,
): Promise<GenerationJobRow | null> {
  const { data } = await supabase
    .from('generation_jobs')
    .select('*')
    .eq('provider_job_id', predictionId)
    .maybeSingle();
  return (data as GenerationJobRow | null) ?? null;
}

export function toVideoMetadata(row: GenerationJobRow, publicAssetBase: string): VideoMetadataRecord {
  const base = publicAssetBase.replace(/\/$/, '');
  return {
    id: row.id,
    user_id: row.user_id,
    original_image_url: `${base}/${row.input_object_key}`,
    replicate_prediction_id: row.provider_job_id,
    prompt: row.prompt,
    style: row.style,
    duration: row.duration_seconds,
    r2_video_url: row.r2_video_url ?? '',
    output_object_key: row.output_object_key ?? '',
    replicate_output_url: row.replicate_output_url,
    created_at: row.created_at,
  };
}
