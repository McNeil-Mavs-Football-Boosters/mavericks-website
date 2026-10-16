-- 246_westlake_week_freshman_6pm_jv_cancelled.sql
--
-- Westlake week, Thu Oct 15. Jeremy 2026-10-14: "Freshman game is moved to
-- 6pm and JV game is cancelled." Confirmed "for this week against Westlake".
-- Source for both changes: Coach (Jeremy 2026-10-14, "Source is coach on both").
--
--   Freshman Green at Westlake, Chaparral Stadium ... 6:30 -> 6:00 p.m.
--   JV vs Westlake, Maverick Stadium (home) ......... CANCELLED
--
-- Venue for the freshman game is unchanged (only the time was reported).
-- Hidden Blue freshman row untouched, same as 225 (no Blue team this season).
-- A cancelled game drops out of /events, the month view and the ICS feed via
-- CALENDAR_STATUSES (see 170); /schedule/games still lists it as cancelled.
--
-- Practice schedule bodies (235/237): the Thursday heading on the varsity/JV
-- bodies said "JV game day", and the closing pointer on all three bodies listed
-- JV at 6:00 home and deferred the freshman time to the Games schedule. Both
-- now reflect the change; the freshman time is stated because Jeremy gave it.
--
-- NOT TOUCHED HERE: lib/fresh-jv-meals.ts Oct 15 slot (Jeremy 2026-10-14:
-- "Don't worry about meal pickups. Leave the same"), varsity team dinner
-- Thu Oct 15 (unaffected), varsity Fri.
--
-- DB-ONLY, NO DEPLOY. Rollback: 246_rollback.sql

begin;

-- Guards: both games still as 235 left them.
do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'freshman' and g.team_designation = 'Green'
     and g.opponent = 'Westlake High School'
     and g.game_date = timestamptz '2026-10-15 18:30 America/Chicago'
     and v.name = 'Chaparral Stadium' and g.result_status = 'scheduled';
  if n <> 1 then raise exception 'freshman Green Oct 15 not found at 6:30 Chaparral (found %, already applied?)', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'jv' and g.team_designation is null
     and g.opponent = 'Westlake High School'
     and g.game_date = timestamptz '2026-10-15 18:00 America/Chicago'
     and v.name = 'Maverick Stadium' and g.result_status = 'scheduled';
  if n <> 1 then raise exception 'JV Oct 15 not found scheduled at 6:00 Maverick Stadium (found %, already applied?)', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27'
     and body like '%Oct 15 at Chaparral Stadium (kickoff time on the Games schedule)%'
     and body like '%JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home)%';
  if n <> 3 then raise exception 'expected 3 practice bodies with the 237 pointer, found %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%### Thursday, Oct 15 — JV game day%';
  if n <> 2 then raise exception 'expected 2 varsity/JV bodies with "JV game day", found %', n; end if;
end $$;

update games
   set game_date = timestamptz '2026-10-15 18:00 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:30 America/Chicago';

update games
   set result_status = 'cancelled', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null
   and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:00 America/Chicago';

update practice_schedules
   set body = replace(replace(replace(body,
         'freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule)',
         'freshmen Thursday Oct 15 at 6:00 p.m. at Chaparral Stadium'),
         'JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home)',
         'JV Thursday Oct 15 cancelled'),
         '### Thursday, Oct 15 — JV game day',
         '### Thursday, Oct 15 — JV game cancelled'),
       updated_at = now()
 where year = '2026-27';

-- Verify.
do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.team_level = 'freshman' and g.team_designation = 'Green'
     and g.opponent = 'Westlake High School'
     and g.game_date = timestamptz '2026-10-15 18:00 America/Chicago'
     and v.name = 'Chaparral Stadium' and g.result_status = 'scheduled';
  if n <> 1 then raise exception 'freshman Green not at 6:00 Chaparral (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'jv' and opponent = 'Westlake High School'
     and game_date = timestamptz '2026-10-15 18:00 America/Chicago'
     and result_status = 'cancelled' and our_score is null and their_score is null;
  if n <> 1 then raise exception 'JV Oct 15 not cancelled cleanly (%)', n; end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity' and opponent = 'Westlake High School'
     and game_date = timestamptz '2026-10-16 19:00 America/Chicago' and result_status = 'scheduled';
  if n <> 1 then raise exception 'varsity Oct 16 disturbed'; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27'
     and (body like '%kickoff time on the Games schedule%'
       or body like '%JV Thursday Oct 15 at 6:00%'
       or body like '%JV game day%'
       or body not like '%freshmen Thursday Oct 15 at 6:00 p.m. at Chaparral Stadium%'
       or body not like '%JV Thursday Oct 15 cancelled%');
  if n <> 0 then raise exception '% practice bodies not updated', n; end if;

  -- 235's rule: no kickoff times in the day sections.
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and regexp_replace(body, '## After Week 11.*$', '', 's') ~ '(5:00|6:00|6:30|7:00) p\.m\.';
  if n <> 0 then raise exception 'a kickoff leaked into a day section'; end if;
end $$;

commit;
