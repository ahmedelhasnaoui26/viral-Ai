import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';

import {
  buildPublicR2Url,
  outputObjectKeyForJob,
  requestPresignedUpload,
  resolveClipDownloadUrl,
  resolveReplicateInputImageUrl,
  uploadImageToR2,
  uploadVideoToR2,
} from './cloudflare_r2_service.ts';
import { clipObjectKey, frameObjectKey } from './extend_video_constants.ts';
import {
  buildPublicInputImageUrl,
  buildReplicateWebhookUrl,
  createPrediction,
  downloadVideoFromReplicate,
  extractOutputVideoUrl,
  getPrediction,
  type ReplicatePrediction,
} from './replicate_service.ts';
import {
  markJobFailed,
  saveVideoMetadataToSupabase,
} from './supabase_video_repository.ts';
import { extractFrameFromClip, frameBytesToDataUrl, mergeClips } from './video_processor_client.ts';

export type ExtendedJobRow = {
  id: string;
  input_object_key: string;
  prompt: string;
  style: string;
  status: string;
  provider_job_id: string | null;
  is_extended: boolean;
  clip_count: number;
  completed_clips: number;
  progress_percent: number;
  extend_phase: string | null;
  current_clip_index: number;
};

/**
 * Extend Video orchestrator:
 * 5s Replicate clips → last-frame chaining → ffmpeg merge → permanent R2 MP4.
 */
export class ExtendVideoService {
  constructor(private readonly supabase: SupabaseClient) {}

  /** Begin extended job: clip rows + start clip 0 from user image. */
  async startExtendedJob(params: {
    jobId: string;
    inputObjectKey: string;
    prompt: string;
    style: string;
    clipCount: number;
    targetDurationSeconds: number;
  }): Promise<void> {
    const { jobId, inputObjectKey, prompt, style, clipCount, targetDurationSeconds } = params;

    await this.supabase.from('generation_jobs').update({
      is_extended: true,
      target_duration_seconds: targetDurationSeconds,
      clip_count: clipCount,
      completed_clips: 0,
      progress_percent: 2,
      extend_phase: 'generating_clips',
      current_clip_index: 0,
      duration_seconds: targetDurationSeconds,
    }).eq('id', jobId);

    const clipRows = Array.from({ length: clipCount }, (_, i) => ({
      job_id: jobId,
      clip_index: i,
      status: i === 0 ? 'processing' : 'queued',
    }));
    await this.supabase.from('generation_clips').insert(clipRows);

    await this.startClip({
      jobId,
      clipIndex: 0,
      inputObjectKey,
      prompt,
      style,
      clipCount,
    });
  }

  private async startClip(params: {
    jobId: string;
    clipIndex: number;
    inputObjectKey: string;
    inputImageUrl?: string;
    prompt: string;
    style: string;
    clipCount: number;
  }): Promise<void> {
    const { jobId, clipIndex, inputObjectKey, inputImageUrl, prompt, style, clipCount } = params;
    const imageUrl = inputImageUrl ?? await this.resolveInputImageUrl(inputObjectKey);

    const prediction = await createPrediction({
      inputImageUrl: imageUrl,
      prompt,
      style,
      webhookUrl: buildReplicateWebhookUrl(),
    });

    const progress = Math.max(2, Math.floor((clipIndex / clipCount) * 85));

    await this.supabase.from('generation_jobs').update({
      status: 'processing',
      provider_job_id: prediction.id,
      current_clip_index: clipIndex,
      progress_percent: progress,
    }).eq('id', jobId);

    await this.supabase.from('generation_clips').update({
      status: 'processing',
      provider_job_id: prediction.id,
    }).eq('job_id', jobId).eq('clip_index', clipIndex);

    console.log('[ExtendVideoService] clip started', jobId, clipIndex, prediction.id);
  }

  async syncExtendedJob(job: ExtendedJobRow): Promise<void> {
    if (!job.is_extended || job.status === 'failed' || job.status === 'completed') return;
    if (job.extend_phase === 'merging' || job.extend_phase === 'done' || !job.provider_job_id) {
      return;
    }

    const { data: clip } = await this.supabase
      .from('generation_clips')
      .select('clip_index, status')
      .eq('job_id', job.id)
      .eq('provider_job_id', job.provider_job_id)
      .maybeSingle();

    if (!clip || clip.status === 'completed' || clip.status === 'archiving') return;

    const prediction = await getPrediction(job.provider_job_id);

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      await markJobFailed(this.supabase, job.id, prediction.error ?? 'Clip generation failed');
      return;
    }

    if (prediction.status !== 'succeeded') return;

    await this.onClipPredictionSucceeded(job, prediction, clip.clip_index as number);
  }

  async handleClipWebhook(prediction: ReplicatePrediction): Promise<void> {
    const { data: clip } = await this.supabase
      .from('generation_clips')
      .select('job_id, clip_index')
      .eq('provider_job_id', prediction.id)
      .maybeSingle();

    if (!clip) return;

    const { data: job } = await this.supabase.from('generation_jobs').select('*').eq(
      'id',
      clip.job_id,
    ).single();

    if (!job?.is_extended) return;

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      await markJobFailed(this.supabase, job.id as string, prediction.error ?? 'Clip failed');
      return;
    }

    if (prediction.status !== 'succeeded') return;

    await this.onClipPredictionSucceeded(
      job as ExtendedJobRow,
      prediction,
      clip.clip_index as number,
    );
  }

  private async resolveInputImageUrl(inputObjectKey: string): Promise<string> {
    if (inputObjectKey.startsWith('http')) return inputObjectKey;
    if (inputObjectKey.includes('extend-frames/')) {
      return await resolveReplicateInputImageUrl(inputObjectKey);
    }
    return buildPublicInputImageUrl(inputObjectKey);
  }

  /**
   * Extract frame via ffmpeg service, pass data URL to Replicate (no R2 fetch required).
   * Optionally backs up frame to R2 under uploads/extend-frames/.
   */
  private async prepareNextClipImageUrl(
    replicateVideoUrl: string,
    frameObjectKey: string,
  ): Promise<string> {
    const { signedUrl: frameUploadUrl } = await requestPresignedUpload(
      frameObjectKey,
      'image/jpeg',
    );
    const frameBytes = await extractFrameFromClip(
      replicateVideoUrl,
      frameUploadUrl,
      frameObjectKey,
    );

    try {
      await uploadImageToR2({ objectKey: frameObjectKey, body: frameBytes });
    } catch (uploadError) {
      console.warn('[ExtendVideoService] frame R2 backup failed (non-fatal)', uploadError);
    }

    return frameBytesToDataUrl(frameBytes);
  }

  /** Only one worker (webhook vs poll) may archive a clip at a time. */
  private async claimClipForArchiving(jobId: string, clipIndex: number): Promise<boolean> {
    const { data: claimed } = await this.supabase
      .from('generation_clips')
      .update({ status: 'archiving' })
      .eq('job_id', jobId)
      .eq('clip_index', clipIndex)
      .eq('status', 'processing')
      .select('clip_index')
      .maybeSingle();

    return claimed != null;
  }

  private async onClipPredictionSucceeded(
    job: ExtendedJobRow,
    prediction: ReplicatePrediction,
    clipIndex: number,
  ): Promise<void> {
    const clipKey = clipObjectKey(job.id, clipIndex);

    const claimed = await this.claimClipForArchiving(job.id, clipIndex);
    if (!claimed) {
      console.log('[ExtendVideoService] clip already archiving/done, skipping', job.id, clipIndex);
      return;
    }

    try {
      const replicateUrl = extractOutputVideoUrl(prediction);
      const downloadResponse = await downloadVideoFromReplicate(replicateUrl);
      if (!downloadResponse.body) throw new Error('Empty Replicate download');

      const hasMoreClips = clipIndex + 1 < job.clip_count;

      // Stream clip to R2 (avoid buffering entire MP4 in Edge memory).
      await uploadVideoToR2({
        objectKey: clipKey,
        body: downloadResponse.body,
        contentType: 'video/mp4',
      });

      await this.supabase.from('generation_clips').update({
        status: 'completed',
        r2_clip_key: clipKey,
        replicate_output_url: replicateUrl,
      }).eq('job_id', job.id).eq('clip_index', clipIndex);

      let nextClipImageUrl: string | undefined;
      if (hasMoreClips) {
        const nextFrameKey = frameObjectKey(job.id, clipIndex + 1);
        console.log('[ExtendVideoService] extract frame for next clip', job.id, clipIndex);
        nextClipImageUrl = await this.prepareNextClipImageUrl(replicateUrl, nextFrameKey);
      }

      const completedClips = clipIndex + 1;
      await this.supabase.from('generation_jobs').update({
        completed_clips: completedClips,
        progress_percent: Math.min(85, Math.floor((completedClips / job.clip_count) * 85)),
      }).eq('id', job.id);

      if (hasMoreClips && nextClipImageUrl) {
        await this.startClip({
          jobId: job.id,
          clipIndex: clipIndex + 1,
          inputObjectKey: frameObjectKey(job.id, clipIndex + 1),
          inputImageUrl: nextClipImageUrl,
          prompt: job.prompt,
          style: job.style,
          clipCount: job.clip_count,
        });
        return;
      }

      await this.mergeAllClips(job.id, job.clip_count, replicateUrl);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Extend video step failed';
      console.error('[ExtendVideoService] clip failed', job.id, clipIndex, message);
      await markJobFailed(this.supabase, job.id, message);
    }
  }

  private async mergeAllClips(
    jobId: string,
    clipCount: number,
    lastReplicateUrl: string,
  ): Promise<void> {
    const { data: merging } = await this.supabase
      .from('generation_jobs')
      .update({
        extend_phase: 'merging',
        progress_percent: 90,
        status: 'archiving',
      })
      .eq('id', jobId)
      .neq('extend_phase', 'merging')
      .neq('extend_phase', 'done')
      .select('id')
      .maybeSingle();

    if (!merging) {
      console.log('[ExtendVideoService] merge already in progress', jobId);
      return;
    }

    const { data: clipRows } = await this.supabase
      .from('generation_clips')
      .select('clip_index, r2_clip_key, replicate_output_url')
      .eq('job_id', jobId)
      .order('clip_index', { ascending: true });

    const clipDownloadUrls: string[] = [];
    for (let i = 0; i < clipCount; i++) {
      const row = clipRows?.find((c) => c.clip_index === i);
      const key = (row?.r2_clip_key as string) ?? clipObjectKey(jobId, i);
      const replicateFallback = row?.replicate_output_url as string | undefined;
      try {
        clipDownloadUrls.push(await resolveClipDownloadUrl(key));
      } catch (r2Error) {
        if (replicateFallback?.startsWith('http')) {
          console.warn('[ExtendVideoService] merge using Replicate URL for clip', i, r2Error);
          clipDownloadUrls.push(replicateFallback);
        } else {
          throw r2Error;
        }
      }
    }
    const finalKey = outputObjectKeyForJob(jobId);
    const { signedUrl: outputUploadUrl } = await requestPresignedUpload(finalKey, 'video/mp4');

    await mergeClips({ clipDownloadUrls, outputUploadUrl });

    await saveVideoMetadataToSupabase(this.supabase, {
      jobId,
      outputObjectKey: finalKey,
      r2VideoUrl: buildPublicR2Url(finalKey),
      replicateOutputUrl: lastReplicateUrl,
    });

    await this.supabase.from('generation_jobs').update({
      extend_phase: 'done',
      progress_percent: 100,
    }).eq('id', jobId);
  }
}
