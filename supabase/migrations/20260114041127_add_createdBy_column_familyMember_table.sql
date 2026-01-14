-- 1. Add the missing 'created_by' column
alter table public.family_members 
add column if not exists created_by uuid references public.profiles(id);

-- 2. Add an index for performance (good practice)
create index if not exists idx_family_members_created_by 
on public.family_members(created_by);

-- 3. Reload the schema cache (Supabase sometimes needs a nudge)
notify pgrst, 'reload schema';