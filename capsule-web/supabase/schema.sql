-- Capsule Database Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Captures table
create table if not exists captures (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  category text not null check (category in ('IDEA', 'VISION', 'REFLECT', 'PLANS')),
  audio_url text,
  audio_file_path text,
  transcript text,
  title text,
  tags text[] default '{}',
  duration real not null default 0,
  is_archived boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable Row Level Security
alter table captures enable row level security;

-- RLS Policies: Users can only access their own captures
create policy "Users can view own captures"
  on captures for select
  using (auth.uid() = user_id);

create policy "Users can insert own captures"
  on captures for insert
  with check (auth.uid() = user_id);

create policy "Users can update own captures"
  on captures for update
  using (auth.uid() = user_id);

create policy "Users can delete own captures"
  on captures for delete
  using (auth.uid() = user_id);

-- Create index for faster queries
create index if not exists captures_user_id_idx on captures(user_id);
create index if not exists captures_category_idx on captures(category);
create index if not exists captures_created_at_idx on captures(created_at desc);

-- Function to update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger to auto-update updated_at
create trigger update_captures_updated_at
  before update on captures
  for each row
  execute function update_updated_at_column();

-- Storage bucket for audio files
-- Note: Create this in Supabase Dashboard > Storage > New Bucket
-- Bucket name: audio
-- Make it private (not public)

-- Storage policies (run after creating the bucket)
-- These allow users to upload/download their own audio files

-- Policy: Users can upload audio to their own folder
-- create policy "Users can upload own audio"
--   on storage.objects for insert
--   with check (
--     bucket_id = 'audio' and
--     auth.uid()::text = (storage.foldername(name))[1]
--   );

-- Policy: Users can read their own audio
-- create policy "Users can read own audio"
--   on storage.objects for select
--   using (
--     bucket_id = 'audio' and
--     auth.uid()::text = (storage.foldername(name))[1]
--   );

-- Policy: Users can delete their own audio
-- create policy "Users can delete own audio"
--   on storage.objects for delete
--   using (
--     bucket_id = 'audio' and
--     auth.uid()::text = (storage.foldername(name))[1]
--   );
