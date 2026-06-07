-- Store temporary Replicate URL per clip for merge fallback if R2 read fails.

alter table generation_clips
  add column if not exists replicate_output_url text;
