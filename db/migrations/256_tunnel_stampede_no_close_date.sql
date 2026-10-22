-- 256_tunnel_stampede_no_close_date.sql
--
-- Jeremy 2026-10-22: remove the line saying Tunnel Stampede registration closes
-- Wednesday; "just leave it open". Ashley had said at the 10/12 meeting that it
-- does not really close Oct 21. One clause out of the description, nothing else.
-- The flyer images (linked at the foot) still print a close date; they are
-- images and are left alone.
--
-- DB-ONLY, NO DEPLOY. Rollback: 256_rollback.sql

begin;

update events
   set description = replace(description,
         'Registration is $10 plus Eventbrite fees and closes Wednesday, October 21. It includes',
         'Registration is $10 plus Eventbrite fees and includes'),
       updated_at = now()
 where slug = 'homecoming-tunnel-stampede-2026'
   and description like '%and closes Wednesday, October 21. It includes%';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'homecoming-tunnel-stampede-2026'
     and description like '%Registration is $10 plus Eventbrite fees and includes the participant''s t-shirt%'
     and description not like '%closes%'
     and description not like '%October 21%';
  if n <> 1 then raise exception 'Stampede description not as intended (%)', n; end if;
end $$;

commit;
