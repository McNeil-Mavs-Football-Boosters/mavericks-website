-- 211_rollback.sql
-- Puts both Cane's rows back exactly as 210 wrote them (5-8 PM, no link, 193 copy).
begin;

update events
   set ends_at = timestamptz '2026-10-26 20:00 America/Chicago',
       signup_url = null, signup_label = null,
       description = 'Join the Mavs for a Spirit Night at Raising Cane''s Chicken Fingers on N I-35 on Monday, October 26, 5:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-raising-canes-2026-10-26';

update events
   set description = 'Join the Mavs for a Spirit Night at Raising Cane''s Chicken Fingers on N I-35 on Monday, November 9, 5:00-8:00 PM. Please mention McNeil Football at the register. That is what tells them your purchase counts, and a portion of it comes back to the team. Wear your Mav shirt. If you do not have one, you can buy one there. Everyone in your party counts, so bring the whole family.',
       updated_at = now()
 where slug = 'spirit-night-raising-canes-2026-11-09';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug like 'spirit-night-raising-canes-%' and signup_url is null
     and description like '%you can buy one there%'
     and extract(hour from ends_at at time zone 'America/Chicago') = 20;
  if n <> 2 then raise exception 'rollback incomplete (%)', n; end if;
end $$;

commit;
