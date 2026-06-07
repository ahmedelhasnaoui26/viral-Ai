-- Permanent R2 video storage: never rely on expiring Replicate CDN URLs.

alter table generation_jobs
  add column if not exists r2_video_url text;

alter table generation_jobs
  add column if not exists replicate_output_url text;

comment on column generation_jobs.output_object_key is
  'R2 object key (e.g. outputs/{jobId}.mp4). Not a Replicate URL.';

comment on column generation_jobs.r2_video_url is
  'Permanent public HTTPS URL on R2 public bucket domain.';

comment on column generation_jobs.replicate_output_url is
  'Temporary Replicate CDN URL (audit only; expires ~1 hour).';

comment on column generation_jobs.provider_job_id is
  'Replicate prediction id (replicate_prediction_id).';

-- Allow archiving status while copying Replicate output to R2.
alter table generation_jobs drop constraint if exists generation_jobs_status_check;
alter table generation_jobs add constraint generation_jobs_status_check
  check (status in ('queued', 'processing', 'archiving', 'completed', 'failed'));
