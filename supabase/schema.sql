create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  handle text unique,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists generation_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  prompt text not null,
  style text not null,
  duration_seconds integer not null default 5,
  template_id uuid,
  status text not null check (status in ('queued', 'processing', 'archiving', 'completed', 'failed')),
  provider text not null default 'replicate',
  provider_job_id text,
  input_object_key text not null,
  output_object_key text,
  r2_video_url text,
  replicate_output_url text,
  error_message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table generation_jobs
  add column if not exists duration_seconds integer not null default 5;

alter table generation_jobs
  add column if not exists template_id uuid;

create table if not exists credits_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  delta integer not null,
  reason text not null,
  created_at timestamptz not null default now()
);

create table if not exists feed_items (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid references auth.users(id) on delete set null,
  creator_handle text not null,
  caption text not null,
  video_url text not null,
  thumbnail_url text,
  template_id uuid,
  views_count integer not null default 0,
  likes_count integer not null default 0,
  shares_count integer not null default 0,
  comments_count integer not null default 0,
  created_at timestamptz not null default now()
);

alter table feed_items
  add column if not exists thumbnail_url text;

alter table feed_items
  add column if not exists template_id uuid;

alter table feed_items
  add column if not exists views_count integer not null default 0;

alter table feed_items
  add column if not exists likes_count integer not null default 0;

alter table feed_items
  add column if not exists shares_count integer not null default 0;

alter table feed_items
  add column if not exists comments_count integer not null default 0;

create table if not exists templates (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  thumbnail_url text not null,
  prompt text not null,
  style text not null,
  duration integer not null default 5,
  aspect_ratio text not null default '9:16',
  category text not null,
  uses_count integer not null default 0,
  likes_count integer not null default 0,
  shares_count integer not null default 0,
  creator_id uuid references auth.users(id) on delete set null,
  is_trending boolean not null default false,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'generation_jobs_template_id_fkey'
  ) then
    alter table generation_jobs
      add constraint generation_jobs_template_id_fkey
      foreign key (template_id) references templates(id) on delete set null;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'feed_items_template_id_fkey'
  ) then
    alter table feed_items
      add constraint feed_items_template_id_fkey
      foreign key (template_id) references templates(id) on delete set null;
  end if;
end $$;

alter table profiles enable row level security;
alter table generation_jobs enable row level security;
alter table credits_ledger enable row level security;
alter table feed_items enable row level security;
alter table templates enable row level security;

drop policy if exists "profiles select own" on profiles;
create policy "profiles select own"
on profiles for select
using (auth.uid() = id);

drop policy if exists "profiles upsert own" on profiles;
create policy "profiles upsert own"
on profiles for all
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "jobs select own" on generation_jobs;
create policy "jobs select own"
on generation_jobs for select
using (auth.uid() = user_id);

drop policy if exists "jobs insert own" on generation_jobs;
create policy "jobs insert own"
on generation_jobs for insert
with check (auth.uid() = user_id);

drop policy if exists "jobs update own" on generation_jobs;
create policy "jobs update own"
on generation_jobs for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "credits select own" on credits_ledger;
create policy "credits select own"
on credits_ledger for select
using (auth.uid() = user_id);

drop policy if exists "feed select all" on feed_items;
create policy "feed select all"
on feed_items for select
using (true);

drop policy if exists "feed insert own" on feed_items;
create policy "feed insert own"
on feed_items for insert
with check (auth.uid() = creator_id);

drop policy if exists "feed update own" on feed_items;
create policy "feed update own"
on feed_items for update
using (auth.uid() = creator_id)
with check (auth.uid() = creator_id);

drop policy if exists "templates select all" on templates;
create policy "templates select all"
on templates for select
using (true);

drop policy if exists "templates insert auth" on templates;
create policy "templates insert auth"
on templates for insert
with check (auth.uid() = creator_id or creator_id is null);

drop policy if exists "templates update owner" on templates;
create policy "templates update owner"
on templates for update
using (auth.uid() = creator_id)
with check (auth.uid() = creator_id);

insert into templates (
  title,
  description,
  thumbnail_url,
  prompt,
  style,
  duration,
  aspect_ratio,
  category,
  uses_count,
  likes_count,
  shares_count,
  is_trending,
  is_premium
) values
  (
    'AI Hug',
    'Create an emotional cinematic hug scene with smooth movement.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/ai-hug.jpg',
    'Two people sharing a warm hug, cinematic motion, dramatic depth of field.',
    'cinematic',
    5,
    '9:16',
    'Transformation',
    12000,
    7400,
    2800,
    true,
    false
  ),
  (
    'Anime Hero',
    'Transform portrait into anime battle entrance with dynamic camera move.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/anime-hero.jpg',
    'Anime hero entrance, dramatic lighting, energy aura and motion blur.',
    'dramatic',
    5,
    '9:16',
    'Anime',
    8400,
    5200,
    1800,
    true,
    false
  ),
  (
    'Luxury Lifestyle',
    'Give photos a high-end old-money cinematic luxury vibe.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/luxury-lifestyle.jpg',
    'Luxury lifestyle editorial look, smooth cinematic camera movement.',
    'dreamy',
    5,
    '9:16',
    'Lifestyle',
    6300,
    3900,
    1100,
    false,
    true
  ),
  (
    'Cyberpunk Glow',
    'Add cyberpunk neon world motion and futuristic mood.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/cyberpunk-glow.jpg',
    'Cyberpunk city atmosphere, neon glow, subtle camera dolly.',
    'ethereal',
    5,
    '9:16',
    'Fantasy',
    5100,
    2500,
    900,
    false,
    true
  )
on conflict do nothing;

-- Run supabase/migrations/002_social_platform.sql then 003_platform_extensions.sql in SQL Editor after this file.
