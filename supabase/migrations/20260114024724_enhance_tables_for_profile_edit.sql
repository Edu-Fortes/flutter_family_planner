-- =================================================================
-- PHASE 1: DATABASE SCHEMA UPDATE
-- =================================================================

-- 1. UPGRADE PROFILES TABLE (Real Users)
-- Safely add columns needed for the new edit screen
alter table public.profiles 
add column if not exists full_name text,
add column if not exists display_name text,
add column if not exists avatar_url text,
add column if not exists color text default '#2196F3';

-- 2. CREATE OR UPGRADE FAMILY_MEMBERS TABLE (Virtual Users)
-- First, ensure the base table exists
create table if not exists public.family_members (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  created_by uuid references public.profiles(id),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Then, safely add the new columns needed for avatars/children
alter table public.family_members 
add column if not exists color text default '#FF9800',
add column if not exists avatar_url text,
add column if not exists is_child boolean default true;

-- 3. CREATE THE UNIFIED VIEW
-- This combines both tables into one list for the MemberScreen
create or replace view public.all_family_members
with (security_invoker = true) as
select 
  p.id, 
  coalesce(p.display_name, p.username) as name, 
  p.color, 
  p.avatar_url, 
  p.role,
  false as is_virtual, -- Real User
  p.id as profile_id   -- Link to auth
from public.profiles p
union all
select 
  fm.id, 
  fm.name, 
  fm.color, 
  fm.avatar_url, 
  'member'::user_role as role, 
  true as is_virtual,  -- Virtual User
  null as profile_id
from public.family_members fm;

-- 4. GRANT PERMISSIONS ON THE VIEW
grant select on public.all_family_members to authenticated;
grant select on public.all_family_members to service_role;

-- 5. ENABLE RLS ON FAMILY MEMBERS
alter table public.family_members enable row level security;

-- Drop old policies if they exist to avoid conflicts
drop policy if exists "Family manage members" on public.family_members;
drop policy if exists "View family members" on public.family_members;

-- Create single optimized policy with proper auth check
create policy "Authenticated users manage family members" on public.family_members 
  for all using ((select auth.role()) = 'authenticated');


-- =================================================================
-- PHASE 2: STORAGE SETUP
-- =================================================================

-- 6. SETUP AVATARS BUCKET
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 7. STORAGE POLICIES
-- Drop existing policies to ensure a clean slate
drop policy if exists "Avatar images are publicly accessible." on storage.objects;
drop policy if exists "Parents can upload avatars." on storage.objects;
drop policy if exists "Parents can update avatars." on storage.objects;

-- Recreate Policies
create policy "Avatar images are publicly accessible." 
  on storage.objects for select using ( bucket_id = 'avatars' );

create policy "Parents can upload avatars." 
  on storage.objects for insert 
  with check ( bucket_id = 'avatars' and auth.role() = 'authenticated' );

create policy "Parents can update avatars." 
  on storage.objects for update 
  using ( bucket_id = 'avatars' and auth.role() = 'authenticated' );