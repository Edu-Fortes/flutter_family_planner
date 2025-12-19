-- 1. PROFILES
-- Create a table for public profiles (linked to auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text,
  avatar_url text,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. FAMILY_EVENTS (Calendar)
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

-- 3. GROCERY_ITEMS (Shopping List)
create table public.grocery_items (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  category text default 'General',
  is_completed boolean default false,
  created_by uuid references public.profiles(id),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 4. REALTIME
-- Enable realtime for these tables so the Pi updates instantly
alter publication supabase_realtime add table public.family_events;
alter publication supabase_realtime add table public.grocery_items;

-- 5. RLS (Security)
alter table public.profiles enable row level security;
alter table public.family_events enable row level security;
alter table public.grocery_items enable row level security;

-- Policies (Simple "Family" Mode: Any logged-in user can do anything)
create policy "Authenticated users can view profiles" on public.profiles
  for select using (auth.role() = 'authenticated');
create policy "Authenticated users can update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Authenticated users can view events" on public.family_events
  for all using (auth.role() = 'authenticated');
  
create policy "Authenticated users can view groceries" on public.grocery_items
  for all using (auth.role() = 'authenticated');

-- 6. AUTOMATIC PROFILE CREATION
-- Function to handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (new.id, new.raw_user_meta_data->>'username');
  return new;
end;
$$ language plpgsql security definer;

-- Trigger the function on new user creation
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();