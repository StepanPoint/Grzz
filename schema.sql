-- MYGENIUS database setup
-- 1) Create a user in Supabase Dashboard > Authentication > Users.
-- 2) Copy that user's UUID and replace ADMIN_USER_UUID below.
-- 3) Run this entire file in SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.albums (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  cover_url text,
  release_date date,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  lyrics text not null default '',
  cover_url text,
  release_date date,
  description text,
  album_id uuid references public.albums(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.annotations (
  id uuid primary key default gen_random_uuid(),
  song_id uuid not null references public.songs(id) on delete cascade,
  line_text text not null,
  body text not null,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.albums enable row level security;
alter table public.songs enable row level security;
alter table public.annotations enable row level security;

-- Public can read. Only the exact owner UUID can write.
-- Replace the UUID in all six write policies with your own Auth user UUID.
create policy "Public read albums" on public.albums for select using (true);
create policy "Owner insert albums" on public.albums for insert
  with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner update albums" on public.albums for update
  using (auth.uid() = 'ADMIN_USER_UUID'::uuid) with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner delete albums" on public.albums for delete
  using (auth.uid() = 'ADMIN_USER_UUID'::uuid);

create policy "Public read songs" on public.songs for select using (true);
create policy "Owner insert songs" on public.songs for insert
  with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner update songs" on public.songs for update
  using (auth.uid() = 'ADMIN_USER_UUID'::uuid) with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner delete songs" on public.songs for delete
  using (auth.uid() = 'ADMIN_USER_UUID'::uuid);

create policy "Public read annotations" on public.annotations for select using (true);
create policy "Owner insert annotations" on public.annotations for insert
  with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner update annotations" on public.annotations for update
  using (auth.uid() = 'ADMIN_USER_UUID'::uuid) with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner delete annotations" on public.annotations for delete
  using (auth.uid() = 'ADMIN_USER_UUID'::uuid);

-- Optional public bucket for album/track artwork.
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

create policy "Public can view covers" on storage.objects for select
  using (bucket_id = 'covers');
create policy "Owner can upload covers" on storage.objects for insert
  with check (bucket_id = 'covers' and auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner can update covers" on storage.objects for update
  using (bucket_id = 'covers' and auth.uid() = 'ADMIN_USER_UUID'::uuid)
  with check (bucket_id = 'covers' and auth.uid() = 'ADMIN_USER_UUID'::uuid);
create policy "Owner can delete covers" on storage.objects for delete
  using (bucket_id = 'covers' and auth.uid() = 'ADMIN_USER_UUID'::uuid);
