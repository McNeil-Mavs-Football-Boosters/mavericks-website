-- 150_rollback.sql — removes the practice-page pointers to the Picture Day
-- event. Nothing is lost from the site: the ordering button itself lives on the
-- event (migration 149) and the practice bodies carry their own picture-day
-- times independently (migration 129).
--
-- Deletes the bullet including its leading newline, so no blank line is left
-- behind inside the Friday block.

begin;

update practice_schedules
set body = replace(
  body,
  E'\n- Photo ordering: see the [Picture Day event](/events/picture-day-2026).',
  ''
)
where year = '2026-27'
  and body like '%/events/picture-day-2026%';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%/events/picture-day-2026%';
  if n <> 0 then
    raise exception '% practice bodies still reference the event', n;
  end if;
end $$;

commit;
