-- =================================================================
-- PHASE 1: PROFILES & VIEW
-- =================================================================

-- 1. UPGRADE PROFILES TABLE (Real Users)
alter table public.profiles 
add column if not exists full_name text,
add column if not exists display_name text,
add column if not exists avatar_url text,
add column if not exists color text default '#2196F3';

-- 2. CREATE THE UNIFIED VIEW
-- Combines 'profiles' (Real) and 'family_members' (Virtual)
create or replace view public.all_family_members
with (security_invoker = true) as
select 
  p.id, 
  coalesce(p.display_name, p.username) as name, 
  p.color, 
  p.avatar_url, 
  p.role,
  false as is_virtual, 
  p.id as profile_id
from public.profiles p
union all
select 
  fm.id, 
  fm.name, 
  fm.color, 
  fm.avatar_url, 
  'member'::user_role as role, 
  true as is_virtual,
  null as profile_id
from public.family_members fm;

-- 3. GRANT PERMISSIONS ON THE VIEW
grant select on public.all_family_members to authenticated;
grant select on public.all_family_members to service_role;

-- =================================================================
-- PHASE 2: STORAGE SETUP
-- =================================================================

-- 4. SETUP AVATARS BUCKET
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 5. STORAGE POLICIES
drop policy if exists "Avatar images are publicly accessible." on storage.objects;
drop policy if exists "Parents can upload avatars." on storage.objects;
drop policy if exists "Parents can update avatars." on storage.objects;

create policy "Avatar images are publicly accessible." 
  on storage.objects for select using ( bucket_id = 'avatars' );

create policy "Parents can upload avatars." 
  on storage.objects for insert 
  with check ( bucket_id = 'avatars' and auth.role() = 'authenticated' );

create policy "Parents can update avatars." 
  on storage.objects for update 
  using ( bucket_id = 'avatars' and auth.role() = 'authenticated' );