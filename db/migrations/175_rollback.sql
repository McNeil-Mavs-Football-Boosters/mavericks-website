-- 175_rollback.sql — puts the Labor Day blocks back to "times will be posted".

begin;

update practice_schedules
   set body = replace(
         replace(body,
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Be at the school no later than **6:30 a.m.**; practice begins at **7:00 a.m.**',
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Coach flagged it a week ahead. Times will be posted with next week''s schedule.'),
         '**Labor Day, Monday Sept 7 — there is practice.**
- **6:30 a.m.** — Arrival, no later than
- **7:00 a.m.** — Practice begins

Coach has not published an end time for Labor Day. Week 6 times will be posted when he publishes that schedule.',
         '**Labor Day, Monday Sept 7 — there is practice.** Times will be posted when Coach publishes the Week 6 schedule.'),
       updated_at = now()
 where year = '2026-27' and team_level in ('varsity','jv');

update practice_schedules
   set body = replace(
         replace(body,
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Be at the school no later than **8:30 a.m.**; practice begins at **9:00 a.m.**',
           '🚨 **Labor Day: there IS practice Monday, Sept 7.** Coach flagged it a week ahead. Times will be posted with next week''s schedule.'),
         '**Labor Day, Monday Sept 7 — there is practice.**
- **8:30 a.m.** — Arrival, no later than
- **9:00 a.m.** — Practice begins

Coach has not published an end time for Labor Day. Week 6 times will be posted when he publishes that schedule.',
         '**Labor Day, Monday Sept 7 — there is practice.** Times will be posted when Coach publishes the Week 6 schedule.'),
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman';

commit;
