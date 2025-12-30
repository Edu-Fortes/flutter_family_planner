-- 1. SETUP TYPES
create type user_role as enum ('admin', 'member');

-- 2. PROFILES TABLE (With Roles)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text,
  role user_role default 'member',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. INVITATIONS TABLE (The Gatekeeper)
create table public.invitations (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  created_by uuid references public.profiles(id),
  is_used boolean default false,
  used_by uuid references public.profiles(id),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 4. FAMILY EVENTS (Calendar)
create table public.family_events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  is_all_day boolean default false,
  color_hex text default '#2196F3',
  created_by uuid references public.profiles(id),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 5. GROCERY ITEMS
create table public.grocery_items (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  category text default 'General',
  is_completed boolean default false,
  created_by uuid references public.profiles(id),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 6. ENABLE REALTIME
alter publication supabase_realtime add table public.family_events;
alter publication supabase_realtime add table public.grocery_items;
alter publication supabase_realtime add table public.profiles;

-- 7. ENABLE RLS (Security)
alter table public.profiles enable row level security;
alter table public.invitations enable row level security;
alter table public.family_events enable row level security;
alter table public.grocery_items enable row level security;

-- 8. DEFINE POLICIES
-- Profiles: View all, Edit own
create policy "View profiles" on public.profiles for select using ((select auth.role()) = 'authenticated');
create policy "Update own profile" on public.profiles for update using ((select auth.uid()) = id);

-- Invitations: Only Admin can touch
create policy "Admins manage invitations" on public.invitations
  for all using (
    exists (select 1 from public.profiles where profiles.id = (select auth.uid()) and profiles.role = 'admin')
  );

-- Events & Groceries: "Family Access" (Everyone can View/Edit everything)
create policy "Family view events" on public.family_events for all using ((select auth.role()) = 'authenticated');
create policy "Family view groceries" on public.grocery_items for all using ((select auth.role()) = 'authenticated');

-- 9. THE GATEKEEPER TRIGGER (Auth Logic)
create or replace function public.handle_new_user()
returns trigger as $$
declare
  is_first_user boolean;
  invite_code text;
  invite_record record;
begin
  -- Check if this is the very first user
  select count(*) = 0 into is_first_user from public.profiles;
  invite_code := new.raw_user_meta_data->>'invitation_code';

  if is_first_user then
    -- Genesis User -> Admin
    insert into public.profiles (id, username, role)
    values (new.id, coalesce(new.raw_user_meta_data->>'username', 'Admin'), 'admin');
  else
    -- Normal User -> Check Code
    if invite_code is null then
      raise exception 'Invitation code required.';
    end if;

    select * into invite_record from public.invitations 
    where code = invite_code and is_used = false;

    if invite_record.id is null then
      raise exception 'Invalid or used invitation code.';
    end if;

    -- Valid -> Create Member Profile
    insert into public.profiles (id, username, role)
    values (new.id, new.raw_user_meta_data->>'username', 'member');

    -- Burn the ticket
    update public.invitations 
    set is_used = true, used_by = new.id 
    where id = invite_record.id;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = '';

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 10. PERFORMANCE INDEXES
-- Add indexes for foreign key columns to improve query performance
create index idx_invitations_created_by on public.invitations(created_by);
create index idx_invitations_used_by on public.invitations(used_by);
create index idx_family_events_created_by on public.family_events(created_by);
create index idx_grocery_items_created_by on public.grocery_items(created_by);