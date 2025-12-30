-- Enable Realtime for the invitations table so the Admin UI updates instantly
alter publication supabase_realtime add table public.invitations;