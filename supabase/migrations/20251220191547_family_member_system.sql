-- 1. FAMILY_MEMBERS TABLE
-- Stores "Virtual Users" (Children/Pets). 
-- Real Users stay in the 'profiles' table.
create table public.family_members (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  color text default '#FF9800', 
  is_child boolean default true,
  avatar_url text, 
  created_by uuid references public.profiles(id), -- Link to Parent
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. INDEX FOR PERFORMANCE
-- (Moved here from the deleted migration file)
create index if not exists idx_family_members_created_by 
on public.family_members(created_by);

-- 3. UPDATE EVENTS TABLE
alter table public.family_events drop column if exists color_hex;
alter table public.family_events add column if not exists assigned_to uuid; 

-- 4. REALTIME & SECURITY
alter publication supabase_realtime add table public.family_members;
alter table public.family_members enable row level security;

-- Policy: Authenticated users (Parents) can view/edit family members
create policy "Authenticated users manage family members" on public.family_members 
  for all using (auth.role() = 'authenticated');