-- Social platform: feed linkage, likes, saves, follows, notifications, profile fields.
-- Safe to re-run (idempotent patterns).

alter table feed_items
  add column if not exists generation_job_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'feed_items_generation_job_id_fkey'
  ) then
    alter table feed_items
      add constraint feed_items_generation_job_id_fkey
      foreign key (generation_job_id) references generation_jobs(id) on delete set null;
  end if;
end $$;

alter table profiles
  add column if not exists bio text;

alter table profiles
  add column if not exists display_name text;

-- Public profile reads for feed / creator cards
drop policy if exists "profiles select public" on profiles;
create policy "profiles select public"
on profiles for select
using (true);

create table if not exists likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  feed_item_id uuid not null references feed_items(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, feed_item_id)
);

create table if not exists saved_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  feed_item_id uuid not null references feed_items(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, feed_item_id)
);

create table if not exists follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  type text not null check (type in ('like', 'follow', 'template_used', 'video_trending')),
  feed_item_id uuid references feed_items(id) on delete cascade,
  template_id uuid references templates(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

alter table likes enable row level security;
alter table saved_posts enable row level security;
alter table follows enable row level security;
alter table notifications enable row level security;

drop policy if exists "likes select all" on likes;
create policy "likes select all"
on likes for select
using (true);

drop policy if exists "likes insert own" on likes;
create policy "likes insert own"
on likes for insert
with check (auth.uid() = user_id);

drop policy if exists "likes delete own" on likes;
create policy "likes delete own"
on likes for delete
using (auth.uid() = user_id);

drop policy if exists "saved select own" on saved_posts;
create policy "saved select own"
on saved_posts for select
using (auth.uid() = user_id);

drop policy if exists "saved insert own" on saved_posts;
create policy "saved insert own"
on saved_posts for insert
with check (auth.uid() = user_id);

drop policy if exists "saved delete own" on saved_posts;
create policy "saved delete own"
on saved_posts for delete
using (auth.uid() = user_id);

drop policy if exists "follows select all" on follows;
create policy "follows select all"
on follows for select
using (true);

drop policy if exists "follows insert own" on follows;
create policy "follows insert own"
on follows for insert
with check (auth.uid() = follower_id);

drop policy if exists "follows delete own" on follows;
create policy "follows delete own"
on follows for delete
using (auth.uid() = follower_id);

drop policy if exists "notifications select own" on notifications;
create policy "notifications select own"
on notifications for select
using (auth.uid() = user_id);

drop policy if exists "notifications insert auth" on notifications;
create policy "notifications insert auth"
on notifications for insert
with check (auth.uid() is not null);

-- Keep feed_items.likes_count in sync
create or replace function public.sync_feed_likes_count_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update feed_items set likes_count = likes_count + 1 where id = new.feed_item_id;
  return new;
end;
$$;

create or replace function public.sync_feed_likes_count_on_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update feed_items set likes_count = greatest(0, likes_count - 1) where id = old.feed_item_id;
  return old;
end;
$$;

drop trigger if exists trg_likes_count_insert on likes;
create trigger trg_likes_count_insert
after insert on likes
for each row execute function public.sync_feed_likes_count_on_insert();

drop trigger if exists trg_likes_count_delete on likes;
create trigger trg_likes_count_delete
after delete on likes
for each row execute function public.sync_feed_likes_count_on_delete();

-- Additional seed templates
insert into templates (
  title, description, thumbnail_url, prompt, style, duration, aspect_ratio, category,
  uses_count, likes_count, shares_count, is_trending, is_premium
) values
  (
    'AI Kiss',
    'Romantic cinematic kiss moment with soft lighting.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/ai-kiss.jpg',
    'Romantic kiss scene, cinematic shallow depth of field, gentle camera push.',
    'dreamy', 5, '9:16', 'Lifestyle', 9200, 4100, 1200, true, false
  ),
  (
    'Movie Trailer',
    'Epic movie trailer pacing with dramatic reveals.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/movie-trailer.jpg',
    'Epic movie trailer energy, dramatic zoom, lens flare, orchestral mood.',
    'cinematic', 10, '9:16', 'Cinematic', 11000, 6200, 2100, true, false
  ),
  (
    'Glow Up',
    'Transformation glow-up with confident energy.',
    'https://pub-8bcf4bf6fced4528ba6a19b9936fb874.r2.dev/templates/glow-up.jpg',
    'Glow up transformation, confident pose, vibrant lighting transition.',
    'dramatic', 5, '9:16', 'Fashion', 7800, 3600, 980, false, false
  )
on conflict do nothing;
