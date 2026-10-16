-- 246_rollback.sql
begin;
update games
   set game_date = timestamptz '2026-10-15 18:30 America/Chicago', updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green'
   and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:00 America/Chicago';
update games
   set result_status = 'scheduled', updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null
   and opponent = 'Westlake High School'
   and game_date = timestamptz '2026-10-15 18:00 America/Chicago'
   and result_status = 'cancelled';
update practice_schedules
   set body = replace(replace(replace(body,
         'freshmen Thursday Oct 15 at 6:00 p.m. at Chaparral Stadium',
         'freshmen Thursday Oct 15 at Chaparral Stadium (kickoff time on the Games schedule)'),
         'JV Thursday Oct 15 cancelled',
         'JV Thursday Oct 15 at 6:00 p.m. at Maverick Stadium (home)'),
         '### Thursday, Oct 15 — JV game cancelled',
         '### Thursday, Oct 15 — JV game day'),
       updated_at = now()
 where year = '2026-27';
commit;
