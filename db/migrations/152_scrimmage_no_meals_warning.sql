-- 152_scrimmage_no_meals_warning.sql
--
-- Coach's Thursday reminder (2026-08-19, the night before) says plainly:
-- "Athletes should bring extra food or a snack. We do not provide meals for
-- scrimmages." Nothing on the site said so. Jeremy asked for it on the page.
--
-- WHY THIS ONE LINE AND NOT THE REST OF THE MESSAGE. Everything else coach sent
-- either already matched or was a rounding difference:
--   * "practice during 2nd period" vs the page's "Period 6" is NOT a conflict.
--     McNeil runs an every-other-day block: periods 1-4 one day, 5-8 the next,
--     and varsity athletics is daily in the same slot - called 2nd on odd days
--     and 6th on even. Thursday Aug 20 is a 5-8 day, so Period 6 is correct.
--     ⚠️ Do not "fix" a Period 2/Period 6 mismatch against a coach message
--     again; check which block day it is first.
--   * on-field times 5:00 and 6:30 in the message vs 4:55 and 6:25 here. The
--     page follows the weekly schedule's arrival-plus-25 convention throughout
--     (7:00→7:25, 9:00→9:20, 8:00→8:25, 4:30→4:55, 6:00→6:25); the reminder
--     rounds. Arrival times - the ones that actually govern when a parent
--     drops off - agree exactly, so the page keeps the precise numbers.
--
-- Placed in the Thursday scrimmage block rather than as a season-wide note.
-- Aug 20 is the LAST scrimmage (Aug 13 was the other; Aug 27 starts games), so
-- a general "scrimmages have no meals" rule has exactly one occurrence left to
-- apply to, and meals ARE provided for games - which is the fact a season-wide
-- placement would blur.
--
-- Anchored to each body's own scrimmage line and asserted per level: varsity
-- carries the 7:00 upperclassmen block, jv and freshman the 5:30 Freshman & JV
-- block. Verified before writing that each anchor occurs exactly once in its
-- body and that no body already mentions a snack.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.

begin;

-- Upperclassmen: after the 7:00 p.m. scrimmage line.
update practice_schedules
set body = replace(
  body,
  E'**7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium',
  E'**7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium\n- **Bring extra food or a snack.** Meals are not provided for scrimmages.'
)
where year = '2026-27'
  and team_level = 'varsity'
  and body like '%**7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium%'
  and body not like '%Meals are not provided for scrimmages%';

-- Freshman & JV: after the 5:30 p.m. scrimmage line, in both bodies.
update practice_schedules
set body = replace(
  body,
  E'**5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium',
  E'**5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium\n- **Bring extra food or a snack.** Meals are not provided for scrimmages.'
)
where year = '2026-27'
  and team_level in ('jv', 'freshman')
  and body like '%**5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium%'
  and body not like '%Meals are not provided for scrimmages%';

-- All three bodies must carry exactly one warning. A replace() that matched
-- nothing returns the body unchanged and reports success - which is how a
-- "done" migration leaves the page without the line it was written to add.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and active
     and (length(body) - length(replace(body, 'Meals are not provided for scrimmages', '')))
         / length('Meals are not provided for scrimmages') = 1;
  if n <> 3 then
    raise exception 'expected 3 bodies with exactly one no-meals warning, found %', n;
  end if;
end $$;

-- It has to sit inside the Thursday block, not wherever replace() put it:
-- after the Thursday header and before Friday's.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and active
     and position('Meals are not provided' in body) > position(E'### Thursday, Aug 20' in body)
     and position('Meals are not provided' in body) < position(E'### Friday, Aug 21' in body);
  if n <> 3 then
    raise exception 'warning landed outside the Thursday block in % of 3 bodies', 3 - n;
  end if;
end $$;

commit;
