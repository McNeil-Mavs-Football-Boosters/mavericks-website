-- Step 2 smoke test only. DELETE before Step 4 along with /dev/ping.
-- Postgrest only exposes public-schema objects; we don't have any tables yet,
-- so this minimal function lets the /dev/ping page prove the wiring works.

create or replace function public.now_utc()
returns timestamptz
language sql
stable
as $$
  select now()
$$;

grant execute on function public.now_utc() to anon, authenticated, service_role;
