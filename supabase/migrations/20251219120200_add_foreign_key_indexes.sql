-- Add indexes on foreign key columns for better query performance
-- This improves JOIN performance and referential integrity checks

-- Index for family_events.created_by foreign key
create index if not exists idx_family_events_created_by 
  on public.family_events(created_by);

-- Index for grocery_items.created_by foreign key
create index if not exists idx_grocery_items_created_by 
  on public.grocery_items(created_by);
