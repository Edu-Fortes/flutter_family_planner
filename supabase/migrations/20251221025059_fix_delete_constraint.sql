-- Drop the old strict constraint
alter table public.family_events
drop constraint family_events_assigned_to_fkey;

-- Add the new smart constraint
-- ON DELETE SET NULL: If the member is deleted, keep the event but make it "Unassigned"
alter table public.family_events
add constraint family_events_assigned_to_fkey
foreign key (assigned_to)
references public.family_members(id)
on delete set null;