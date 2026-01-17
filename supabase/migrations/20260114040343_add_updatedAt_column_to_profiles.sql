-- 1. Add the missing column
alter table public.profiles 
add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now());

-- 2. Create a function to auto-update the timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 3. Create the trigger (so you don't have to send 'updated_at' from Flutter)
create trigger on_profiles_updated
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();