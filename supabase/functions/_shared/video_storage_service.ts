import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';

import {
  downloadVideoFromReplicate,
  extractOutputVideoUrl,
  getPrediction,
  type ReplicatePrediction,
} from './replicate_service.ts';
import {
  isPermanentR2ObjectKey,
  outputObjectKeyForJob,
  uploadVideoToR2,
} from './cloudflare_r2_service.ts';
import {
  findJobByPredictionId,
  markJobArchiving,
  markJobFailed,
  saveVideoMetadataToSupabase,
  type VideoMetadataRecord,
} from './supabase_video_repository.ts';

export type { VideoMetadataRecord };

/**
 * Production pipeline: Replicate inference → download → R2 upload → Supabase metadata.
 *
 * Never store Replicate CDN URLs as the canonical video reference.
 */
export class VideoStorageService {
  constructor(private readonly supabase: SupabaseClient) {}

  /**
   * After Replicate reports success, copy the video to R2 and persist metadata.
   * Streams bytes directly from Replicate to R2 to avoid memory leaks.
   */
  async archivePredictionOutput(params: {
    jobId: string;
    prediction: ReplicatePrediction;
  }): Promise<VideoMetadataRecord> {
    const { jobId, prediction } = params;

    // Step A — Validate prediction output.
    let replicateOutputUrl: string;
    try {
      replicateOutputUrl = extractOutputVideoUrl(prediction);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Missing Replicate output';
      await markJobFailed(this.supabase, jobId, message);
      throw error;
    }

    // Step B — Mark job as archiving (client polls until completed).
    await markJobArchiving(this.supabase, jobId);

    const objectKey = outputObjectKeyForJob(jobId);

    try {
      // Step C — Download temporary video from Replicate (stream).
      const downloadResponse = await downloadVideoFromReplicate(replicateOutputUrl);
      const contentType = downloadResponse.headers.get('content-type') ?? 'video/mp4';

      if (!downloadResponse.body) {
        throw new Error('Replicate download returned empty body');
      }

      // Step D — Upload stream to permanent R2 storage.
      const { r2VideoUrl } = await uploadVideoToR2({
        objectKey,
        body: downloadResponse.body,
        contentType,
      });

      // Step E — Save metadata to Supabase (permanent URL + R2 key).
      return await saveVideoMetadataToSupabase(this.supabase, {
        jobId,
        outputObjectKey: objectKey,
        r2VideoUrl,
        replicateOutputUrl,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Video archival failed';
      console.error('[VideoStorageService] archivePredictionOutput failed', jobId, message);
      await markJobFailed(this.supabase, jobId, message);
      throw error;
    }
  }

  /**
   * Poll Replicate once and archive when succeeded.
   * Used by get-generation-job when webhooks are unavailable.
   */
  async syncProcessingJob(job: {
    id: string;
    status: string;
    provider_job_id: string | null;
    output_object_key: string | null;
  }): Promise<VideoMetadataRecord | null> {
    if (!job.provider_job_id) return null;

    // Already archived to R2.
    if (job.status === 'completed' && isPermanentR2ObjectKey(job.output_object_key)) {
      return null;
    }

    // Legacy rows: completed but still holding a Replicate HTTPS URL.
    if (
      job.status === 'completed' &&
      job.output_object_key?.startsWith('http')
    ) {
      const prediction = await getPrediction(job.provider_job_id);
      if (prediction.status === 'succeeded') {
        return await this.archivePredictionOutput({ jobId: job.id, prediction });
      }
      return null;
    }

    if (job.status !== 'processing' && job.status !== 'archiving') {
      return null;
    }

    const prediction = await getPrediction(job.provider_job_id);

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      await markJobFailed(
        this.supabase,
        job.id,
        prediction.error ?? `Prediction ${prediction.status}`,
      );
      return null;
    }

    if (prediction.status !== 'succeeded') {
      return null;
    }

    return await this.archivePredictionOutput({ jobId: job.id, prediction });
  }

  /** Handle Replicate webhook POST payloads. */
  async handleWebhookPrediction(prediction: ReplicatePrediction): Promise<VideoMetadataRecord | null> {
    const job = await findJobByPredictionId(this.supabase, prediction.id);
    if (!job) {
      console.warn('[VideoStorageService] Webhook: no job for prediction', prediction.id);
      return null;
    }

    if (job.status === 'completed' && isPermanentR2ObjectKey(job.output_object_key)) {
      return null;
    }

    if (prediction.status === 'failed' || prediction.status === 'canceled') {
      await markJobFailed(this.supabase, job.id, prediction.error ?? 'Prediction failed');
      return null;
    }

    if (prediction.status !== 'succeeded') {
      return null;
    }

    return await this.archivePredictionOutput({ jobId: job.id, prediction });
  }
}
