-- 1. FAMILY_MEMBERS TABLE
-- This unifies "Real Users" (Mom/Dad) and "Virtual Users" (Kids)
create table public.family_members (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  color text default '#2196F3', -- Blue default
  is_child boolean default false,
  profile_id uuid references public.profiles(id) on delete set null, -- Link to login if exists
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. SYNC TRIGGER (Profile -> Member)
-- When a user registers, automatically create a Member entry for them
create or replace function public.handle_new_member_sync()
returns trigger
set search_path = ''
as $$
begin
  insert into public.family_members (name, profile_id, color)
  values (new.username, new.id, '#9C27B0'); -- Purple for Adults
  return new;
end;
$$ language plpgsql security definer;

create trigger on_profile_created
  after insert on public.profiles
  for each row execute procedure public.handle_new_member_sync();

-- 3. BACKFILL (Fix existing admins/users)
-- If you already have users, this creates member records for them now.
insert into public.family_members (name, profile_id, color)
select username, id, '#9C27B0'
from public.profiles
where id not in (select profile_id from public.family_members where profile_id is not null);

-- 4. UPDATE EVENTS TABLE
-- We drop the old 'color_hex' because color now belongs to the Member.
-- We add 'assigned_to' to know who this event is for.
alter table public.family_events drop column if exists color_hex;
alter table public.family_events add column assigned_to uuid references public.family_members(id);

-- 5. REALTIME & SECURITY
alter publication supabase_realtime add table public.family_members;
alter table public.family_members enable row level security;

-- Note: RLS policy for family_members is defined in migration 20260114024724_enhance_tables_for_profile_edit.sql