-- Phase 5–15: comments, drafts, reports, moderation, credits, notification types.

-- Comments
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  feed_item_id uuid not null references feed_items(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create index if not exists comments_feed_item_id_idx on comments(feed_item_id);

alter table comments enable row level security;

drop policy if exists "comments select all" on comments;
create policy "comments select all" on comments for select using (true);

drop policy if exists "comments insert own" on comments;
create policy "comments insert own" on comments for insert with check (auth.uid() = user_id);

drop policy if exists "comments delete own" on comments;
create policy "comments delete own" on comments for delete using (auth.uid() = user_id);

create or replace function public.sync_feed_comments_count_on_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update feed_items set comments_count = comments_count + 1 where id = new.feed_item_id;
  return new;
end;
$$;

create or replace function public.sync_feed_comments_count_on_delete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update feed_items set comments_count = greatest(0, comments_count - 1) where id = old.feed_item_id;
  return old;
end;
$$;

drop trigger if exists trg_comments_count_insert on comments;
create trigger trg_comments_count_insert after insert on comments
for each row execute function public.sync_feed_comments_count_on_insert();

drop trigger if exists trg_comments_count_delete on comments;
create trigger trg_comments_count_delete after delete on comments
for each row execute function public.sync_feed_comments_count_on_delete();

-- Draft generations
create table if not exists draft_generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_url text,
  prompt text not null default '',
  style text not null default 'cinematic',
  duration integer not null default 5,
  template_id uuid references templates(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table draft_generations enable row level security;

drop policy if exists "drafts select own" on draft_generations;
create policy "drafts select own" on draft_generations for select using (auth.uid() = user_id);

drop policy if exists "drafts insert own" on draft_generations;
create policy "drafts insert own" on draft_generations for insert with check (auth.uid() = user_id);

drop policy if exists "drafts update own" on draft_generations;
create policy "drafts update own" on draft_generations for update using (auth.uid() = user_id);

drop policy if exists "drafts delete own" on draft_generations;
create policy "drafts delete own" on draft_generations for delete using (auth.uid() = user_id);

-- Reports
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('video', 'comment', 'user')),
  target_id text not null,
  reason text not null,
  created_at timestamptz not null default now()
);

alter table reports enable row level security;

drop policy if exists "reports insert own" on reports;
create policy "reports insert own" on reports for insert with check (auth.uid() = reporter_id);

-- Moderation queue (admin uses service role)
create table if not exists moderation_queue (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('video', 'comment', 'user')),
  target_id text not null,
  report_id uuid references reports(id) on delete set null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'removed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table moderation_queue enable row level security;

drop policy if exists "moderation select pending" on moderation_queue;
create policy "moderation select pending" on moderation_queue for select using (true);

drop policy if exists "moderation insert authenticated" on moderation_queue;
create policy "moderation insert authenticated" on moderation_queue
for insert with check (auth.uid() is not null);

-- User credits
create table if not exists user_credits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance integer not null default 1,
  plan text not null default 'free' check (plan in ('free', 'pro', 'creator_plus')),
  watermark_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table user_credits enable row level security;

drop policy if exists "credits select own" on user_credits;
create policy "credits select own" on user_credits for select using (auth.uid() = user_id);

-- Expand notification types (drop/recreate check)
alter table notifications drop constraint if exists notifications_type_check;
alter table notifications add constraint notifications_type_check
  check (type in ('like', 'comment', 'follow', 'template_used', 'video_trending'));

-- Auto-create profile + credits on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, handle, display_name)
  values (new.id, '@' || left(new.id::text, 8), 'Creator')
  on conflict (id) do nothing;

  insert into user_credits (user_id, balance, plan, watermark_enabled)
  values (new.id, 1, 'free', true)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- RPC: increment feed view
create or replace function public.increment_feed_view(p_feed_item_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update feed_items set views_count = views_count + 1 where id = p_feed_item_id;
end;
$$;

grant execute on function public.increment_feed_view(uuid) to anon, authenticated;

-- RPC: increment feed share count
create or replace function public.increment_feed_share(p_feed_item_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update feed_items set shares_count = shares_count + 1 where id = p_feed_item_id;
end;
$$;

grant execute on function public.increment_feed_share(uuid) to anon, authenticated;
