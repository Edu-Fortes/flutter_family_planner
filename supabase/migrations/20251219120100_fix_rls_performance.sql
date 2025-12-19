-- Fix auth_rls_initplan performance warnings
-- Wrap auth.role() and auth.uid() calls in SELECT to evaluate once per query

-- Drop existing policies
drop policy if exists "Authenticated users can view profiles" on public.profiles;
drop policy if exists "Authenticated users can update own profile" on public.profiles;
drop policy if exists "Authenticated users can view events" on public.family_events;
drop policy if exists "Authenticated users can view groceries" on public.grocery_items;

-- Recreate policies with optimized auth function calls
create policy "Authenticated users can view profiles" on public.profiles
  for select using ((select auth.role()) = 'authenticated');

create policy "Authenticated users can update own profile" on public.profiles
  for update using ((select auth.uid()) = id);

create policy "Authenticated users can view events" on public.family_events
  for all using ((select auth.role()) = 'authenticated');
  
create policy "Authenticated users can view groceries" on public.grocery_items
  for all using ((select auth.role()) = 'authenticated');
