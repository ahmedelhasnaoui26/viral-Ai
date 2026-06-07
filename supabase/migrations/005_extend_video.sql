-- Extend Video: multi-clip generation (5s per clip) merged into one permanent R2 output.

alter table generation_jobs
  add column if not exists is_extended boolean not null default false;

alter table generation_jobs
  add column if not exists target_duration_seconds integer;

alter table generation_jobs
  add column if not exists clip_count integer not null default 1;

alter table generation_jobs
  add column if not exists completed_clips integer not null default 0;

alter table generation_jobs
  add column if not exists progress_percent integer not null default 0;

alter table generation_jobs
  add column if not exists extend_phase text
    check (extend_phase is null or extend_phase in ('generating_clips', 'merging', 'done'));

alter table generation_jobs
  add column if not exists current_clip_index integer not null default 0;

create table if not exists generation_clips (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references generation_jobs(id) on delete cascade,
  clip_index integer not null,
  provider_job_id text,
  r2_clip_key text,
  status text not null default 'queued'
    check (status in ('queued', 'processing', 'archiving', 'completed', 'failed')),
  error_message text,
  created_at timestamptz not null default now(),
  unique (job_id, clip_index)
);

create index if not exists generation_clips_job_id_idx on generation_clips(job_id);
create index if not exists generation_clips_provider_job_id_idx on generation_clips(provider_job_id);

alter table generation_clips enable row level security;

drop policy if exists "clips select own job" on generation_clips;
create policy "clips select own job"
  on generation_clips for select
  using (
    exists (
      select 1 from generation_jobs g
      where g.id = generation_clips.job_id and g.user_id = auth.uid()
    )
  );
